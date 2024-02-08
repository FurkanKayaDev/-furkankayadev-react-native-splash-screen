/**
 * SplashScreen
 * Author: Furkankayadev
 * GitHub: https://github.com/furkankayadev
 */

#import "RNSplashScreen.h"
#import <React/RCTBridge.h>

static bool waiting = true;
static bool addedJsLoadErrorObserver = false;
static UIView *loadingView = nil;

@implementation RNSplashScreen

- (NSArray<NSString *> *)supportedEvents {
  return @[@"onSplashHide", @"onSplashError"];
}

- (void)show {
  if (!addedJsLoadErrorObserver) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jsLoadError:) name:RCTJavaScriptDidFailToLoadNotification object:nil];
    addedJsLoadErrorObserver = true;
  }

  while (waiting) {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
  }
}

- (void)showSplash:(NSString *)splashScreen inRootView:(UIView *)rootView {
  if (!loadingView) {
    loadingView = [[[NSBundle mainBundle] loadNibNamed:splashScreen owner:self options:nil] objectAtIndex:0];
    CGRect frame = rootView.frame;
    frame.origin = CGPointMake(0, 0);
    loadingView.frame = frame;
  }

  [rootView addSubview:loadingView];
}

- (void)hide {
  if (waiting) {
    dispatch_async(dispatch_get_main_queue(), ^{
      waiting = false;
      dispatch_semaphore_signal(self.semaphore);
    });
  } else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [loadingView removeFromSuperview];
      [self sendEventWithName:@"onSplashHide"];
    });
  }
}

- (void)jsLoadError:(NSNotification *)notification {
  // Hide the splash screen if there was an error loading JavaScript.
  [self hide];
  [self sendEventWithName:@"onSplashError" body:@{@"error": notification.userInfo[@"error"]}];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end