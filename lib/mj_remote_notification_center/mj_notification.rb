class MJNotification

  attr_reader :notificationName, :peer, :peerID, :userInfo

  def init(notificationName, peer, info)
    @notificationName = notificationName
    @peer             = peer
    @peerID           = peer.peerID
    @userInfo         = info

    self
  end

  def data
    NSMutableData.alloc.init.tap do |data|
      archiver = NSKeyedArchiver.alloc.initForWritingWithMutableData data

      archiver.encodeObject @notificationName, forKey: "notificationName"
      archiver.encodeObject @peerID,           forKey: "peerID"
      archiver.encodeObject @userInfo,         forKey: "userInfo"

      archiver.finishEncoding
    end
  end

  def self.fromData(data, peerList)
    unarchiver = NSKeyedUnarchiver.alloc.initForReadingWithData data

    notificationName = unarchiver.decodeObjectForKey "notificationName"
    peerID           = unarchiver.decodeObjectForKey "peerID"
    peer             = peerList.peerWithID peerID
    userInfo         = unarchiver.decodeObjectForKey "userInfo"

    unarchiver.finishDecoding

    MJNotification.alloc.init(notificationName, peer, userInfo)
  end

end
