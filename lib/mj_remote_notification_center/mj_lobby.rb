class MJLobby

  def self.defaultLobby
    @defaultLobby
  end

  def self.defaultLobby=(lobby)
    @defaultLobby = lobby
  end

  def init(session)
    MJLobby.defaultLobby = self

    @session = session
    @peers   = Hash.new

    selfPeer

    self
  end

  def allPeersCount
    @peers.keys.length
  end

  def connectedPeersCount
    connectedPeers.length
  end

  def findOrCreatePeer(peerID)
    peerName = @session.displayNameForPeer peerID

    @peers[ peerID ] ||= MJPeer.alloc.init(peerName, peerID)
  end

  def gotUUID(notification)
    uuid      = notification.userInfo
    peer      = notification.peer
    oldPeer   = @peers.values.detect { |peer| peer.uuid == uuid }

    NSLog("Got UUID = #{ uuid }, new peer = #{ peer.peerID }, peer = #{ oldPeer && oldPeer.peerID }")

    if oldPeer
      @peers[ peer.peerID ] = oldPeer
      oldPeer.updateWithPeer peer
    else
      peer.uuid = notification.userInfo

      MJRemoteNotificationCenter.defaultCenter.notifyLocally "MJPeerJoined", peer: peer, userInfo: nil
    end
  end

  def peerJoined(peer)
    center = MJRemoteNotificationCenter.defaultCenter

    center.postNotificationName "RNCPeerUUID", userInfo: center.uuid
  end

  def peerLeft(peer)
    MJRemoteNotificationCenter.defaultCenter.notifyLocally "MJPeerLeft",   peer: peer, userInfo: nil
  end

  def peerWithID(peerID)
    findOrCreatePeer peerID
  end

  def peerWithUUID(uuid)
    @peers.values.detect { |peer| peer.uuid == uuid }
  end

  def selfPeer
    findOrCreatePeer @session.peerID
  end

  def connectedPeers
    puts "connectedPeers, know #{ @peers.values.length } peers #{ @peers.values.map { |p| p.__quick.to_s }.join ' ' }"
    @peers.values.select { |peer| peer.connected? }.uniq
  end

end
