class MJRemoteNotificationObserver

  attr_reader :target, :action, :notificationName, :peer

  def init(target, action, notificationName, peer)
    @target           = target
    @action           = action
    @notificationName = notificationName
    @peer             = peer

    self
  end

  def looseMatch?(target, notificiationName, peer)
    @target == target && @notificationName == notificationName && @peer == peer
  end

  def match?(other)
    @target == other.target && @action == other.action && @notificationName == other.notificationName && @peer == other.peer
  end

  def observing?(notification)
    byName = @notificationName == nil || @notificationName == notification.notificationName
    byPeer = @peer             == nil || @peer.peerID      == notification.peerID

    byName && byPeer
  end

  def observeNotification(notification)
    @target.send(@action, notification)
  end

end
