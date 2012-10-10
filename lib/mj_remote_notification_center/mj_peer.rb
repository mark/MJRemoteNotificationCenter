class MJPeer

  attr_accessor :peerID
  attr_reader   :uuid

  def init(peerName, peerID)
    @peerName = peerName
    @peerID   = peerID

    @status = :disconnected

    self
  end

  def connected!
    return if @status == :connected
    @status = @uuid ? :connected : :waiting_for_uuid

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

  def uuid=(uuid)
    @uuid   = uuid
    @status = :connected unless isSelf?
  end

end
