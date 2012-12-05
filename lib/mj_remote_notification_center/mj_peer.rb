class MJPeer

  attr_accessor :peerID
  attr_reader   :uuid
  attr_accessor :flag
  
  def init(peerName, peerID)
    puts "MJPeer#init #{ peerName } / #{ peerID }"
    @peerName = peerName
    @peerID   = peerID

    @status = :disconnected

    self
  end

  def connected!
    @status = @uuid ? :connected : :waiting_for_uuid
    return if @status == :connected

    NSLog("Connected with #{ peerID }, waiting for uuid")
    MJLobby.defaultLobby.peerJoined(self)
  end

  def connected?
    @status == :connected
  end

  def disconnected!
    return unless connected?
    @status = :disconnected

    MJLobby.defaultLobby.peerLeft(self)
  end

  def disconnected?
    @status == :disconnected
  end

  def isSelf?
    self == MJLobby.defaultLobby.selfPeer
  end

  def name
    @peerName
  end

  def postNotification(notificationName, userInfo: userInfo)
    MJRemoteNotificationCenter.defaultCenter.postNotificationToPeer peerID, name: notificationName, userInfo: userInfo
  end
  
  def updateWithPeer(newPeer)
    @flag ||= rand(1000).to_s
    puts "in updateWithPeer, look like #{ __quick }"
    connected!

    @peerID = newPeer.peerID

    MJRemoteNotificationCenter.defaultCenter.notifyLocally "MJPeerUpdated", peer: self, userInfo: nil
  end

  def uuid=(uuid)
    @uuid   = uuid
    @status = :connected unless isSelf?
  end

  def __quick
    "#{ isSelf? }:#{ @peerID }:#{ @status }:#{ @flag }"
  end
  
end
