class DummyViewController < UIViewController

  def dummyView
    @dummyView ||= UIView.alloc.init.tap do |view|
    end
  end
  
  def viewDidLoad
    self.view = dummyView
    
    button1 = UIButton.buttonWithType UIButtonTypeRoundedRect
    button1.frame = CGRectMake(20, 20.0, 280.0, 30.0)
    button1.setTitle "Say 'Hello!'", forState: UIControlStateNormal
    button1.addTarget self, action: "sayHello", forControlEvents: UIControlEventTouchUpInside
    
    button2 = UIButton.buttonWithType UIButtonTypeRoundedRect
    button2.frame = CGRectMake(20, 70.0, 280.0, 30.0)
    button2.setTitle "Say 'World!'", forState: UIControlStateNormal
    button2.addTarget self, action: "sayWorld", forControlEvents: UIControlEventTouchUpInside

    @label = UILabel.alloc.initWithFrame CGRectMake(20.0, 400.0, 280.0, 30.0)
    @label.text = "...waiting..."

    view.addSubview button1
    view.addSubview button2
    view.addSubview @label
    
    MJRemoteNotificationCenter.defaultCenter.addObserver self,
      selector: "heardMessage:",
      name:     "DummyMessage",
      peer:     nil
  end
  
  def sayHello
    # NSLog "Hello"
    MJRemoteNotificationCenter.defaultCenter.postNotificationName "DummyMessage", userInfo: "Hello!"
  end
  
  def sayWorld
    # NSLog "World"
    MJRemoteNotificationCenter.defaultCenter.postNotificationName "DummyMessage", userInfo: "World!"
  end
  
  def heardMessage(notification)
    @label.text = "You heard '#{notification.userInfo}'"
  end
  
end
