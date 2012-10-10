class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    UIApplication.sharedApplication.setStatusBarHidden(true, withAnimation: UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    @window.rootViewController = viewController
    @window.rootViewController.wantsFullScreenLayout = true

    @window.makeKeyAndVisible
    true
  end
  
  def viewController
    @viewController ||= DummyViewController.alloc.initWithNibName(nil, bundle: nil)
  end
  
end
