class MJRemoteNotificationCenter

  ################
  #              #
  # Declarations #
  #              #
  ################
  
  attr_accessor :uuid

  #################
  #               #
  # Class Methods #
  #               #
  #################
  
  def self.defaultCenter
    @defaultCenter ||= MJRemoteNotificationCenter.alloc.init
  end

  ###############
  #             #
  # Constructor #
  #             #
  ###############

  def init
    generateUUID
    establishSession

    nc = NSNotificationCenter.defaultCenter

    nc.addObserver self, selector: "becomeActive:",    name: "UIApplicationDidBecomeActiveNotification",     object: nil
    nc.addObserver self, selector: "enterBackground:", name: "UIApplicationDidEnterBackgroundNotification",  object: nil
    nc.addObserver self, selector: "enterForeground:", name: "UIApplicationWillEnterForegroundNotification", object: nil
    nc.addObserver self, selector: "resignActive:",    name: "UIApplicationWillResignActiveNotification",    object: nil
    nc.addObserver self, selector: "terminate:",       name: "UIApplicationWillTerminateNotification",       object: nil

    @observers = {}

    addObserver MJLobby.defaultLobby, selector: "gotUUID:", name: "RNCPeerUUID", peer: nil

    MJLobby.defaultLobby.selfPeer.uuid = @uuid
    
    self
  end

  ####################
  #                  #
  # Instance Methods #
  #                  #
  ####################
  
  def clearSession
    return unless @session

    @session.disconnectFromAllPeers
    @session.available = false
    @session.delegate  = nil
    @session.setDataReceiveHandler nil, withContext: nil
    @session = nil
  end

  def establishSession
    return if @session

    @session = GKSession.alloc.initWithSessionID nil, displayName: nil, sessionMode: GKSession::GKSessionModePeer
    @session.setDataReceiveHandler self, withContext: nil

    @session.delegate          = self
    @session.disconnectTimeout = 5.0
    @session.available         = true

    @peerList ||= MJLobby.alloc.init(@session)
  end

  def generateUUID
    defaults = NSUserDefaults.standardUserDefaults

    if defaults.stringForKey("UUID")
      @uuid = defaults.stringForKey("UUID")
    else
      theUUID = CFUUIDCreate(nil);
      @uuid = CFUUIDCreateString(nil, theUUID);
      CFRelease(theUUID);
      defaults.setObject(@uuid, forKey: "UUID")
    end

    NSLog("UUID = #{ @uuid }")
  end

  def peers
    @peerList
  end

  #######################################
  #                                     #
  # NotificationCenter Observer Methods #
  #                                     #
  #######################################

  def becomeActive(notification)
    puts "becomeActive"
    establishSession
  end

  def enterForeground(notification)
    puts "enterForeground"
    establishSession
  end

  def resignActive(notification)
    puts "resignActive"
  end

  def enterBackground(notification)
    puts "enterBackground"
    clearSession
  end

  def terminate(notification)
    puts "terminate"
    clearSession
  end

  #########################
  #                       #
  # Registering Observers #
  #                       #
  #########################
  
  def addObserver(observer, selector: selector, name: notificationName, peer: peer)
    observer = MJRemoteNotificationObserver.alloc.init(observer, selector, notificationName, peer)
    return if observerExists?( observer )

    if notificationName || peer
      @observers[ notificationName ] ||= []
      @observers[ notificationName ] << observer
    else
      # This wants to observe all notifications, probably don't let it...
    end

  end

  def addLocalNotificationName(localNotificationName, selector: selector, name: notificationName, peer: peer)
    # Route remote notification to a local notification...
  end

  def observerExists?(observer)
    return unless @observers[ observer.notificationName ]

    @observers[ observer.notificationName ].detect { |obs| obs.match? observer }
  end

  ######################
  #                    #
  # Removing Observers #
  #                    #
  ######################

  def removeObserver(observer)
    @observers.values.each do |observers|
      observers.delete_if { |obs| obs.target == observer }
    end
  end

  def removeObserver(observer, name: notificationName, peer: peer)
    return unless @observers[ observer.notificationName ]

    @observers[ observer.notificationName ].delete_if { |obs|
      obs.looseMatch? observer, notificationName, peer
    }
  end
  
  #########################
  #                       #
  # Posting Notifications #
  #                       #
  #########################
  
  def postNotificationName(notificationName, userInfo: info)
    postNotificationToPeers :all, name: notificationName, userInfo: info
  end

  def postNotificationToPeer(peerID, name: notificationName, userInfo: info)
    postNotificationToPeers [ peerID ], name: notificationName, userInfo: info
  end

  def postNotificationToPeers(peerIDs, name: notificationName, userInfo: info)
    return unless @session

    notification = MJNotification.alloc.init(notificationName, @peerList.selfPeer, info)
    pointer      = Pointer.new :object

    if peerIDs == :all
      @session.sendDataToAllPeers notification.data, withDataMode: GKSendDataReliable, error: pointer
    else
      @session.sendData notification.data, toPeers: peerIDs, withDataMode: GKSendDataReliable, error: pointer
    end

    if error = pointer[0]
      notifyLocally "MJPostNotificationFailed", peer: nil, userInfo: { :notification => notification, :error => error }
    end
  end

  ###########################
  #                         #
  # Receiving Notifications #
  #                         #
  ###########################

  def notifyLocally(localNotificationName, peer: peer, userInfo: userInfo)
    peer ||= @peerList.selfPeer
    notification = MJNotification.alloc.init(localNotificationName, peer, userInfo)

    notifyObservers(notification)
  end

  def notifyObservers(notification)
    observersForNotification(notification).each { |obs| obs.observeNotification notification }
  end

  def observersForNotification(notification)
    observersForNotificationName = @observers[ notification.notificationName ] || []
    observersForPeer             = @observers[ nil ]                           || []
    potentialObservers           = observersForNotificationName + observersForPeer

    potentialObservers.select { |obs| obs.observing? notification }
  end

  def receiveData(data, fromPeer: peerID, inSession: session, context: context)
    notification = MJNotification.fromData data, @peerList

    notifyObservers notification
  end

  ##############################
  #                            #
  # GKSession Delegate Methods #
  #                            #
  ##############################

  def session(session, peer: peerID, didChangeState: state)
    return if peerID == session.peerID
    # puts "session: peer: #{ peerID } didChangeState: #{ state }"

    peer = @peerList.peerWithID(peerID)

    if state == GKPeerStateAvailable
      session.connectToPeer peerID, withTimeout: 4.0
    elsif state == GKPeerStateConnected
      peer.connected!
    elsif state == GKPeerStateDisconnected
      peer.disconnected!
    end
  end

  def session(session, didReceiveConnectionRequestFromPeer: peerID)
    pointer = Pointer.new :object

    session.acceptConnectionFromPeer peerID, error: pointer

    if error = pointer[0]
      notifyLocally "MJAcceptConnectionFailed", peer: nil, userInfo: { :peerID => peerID }
    end
  end

  def session(session, connectionWithPeerFailed: peerID, withError: error)
    notifyLocally "MJConnectionWithPeerFailed", peer: nil, userInfo: { :peerID => peerID, :error => error }
  end

  def session(session, didFailWithError: error)
    notifyLocally "MJSessionFailed", peer: nil, userInfo: { :session => session, :error => error }
  end
  
end
