//
//  GIFBlender.h
//  
//
//  Created by John Weaver on 10/22/2016.
//
//

#import <Cordova/CDVPlugin.h>

@interface GIFBlender : CDVPlugin < UINavigationControllerDelegate, UIScrollViewDelegate>

@property (copy)   NSString* callbackId;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (void)blend:(CDVInvokedUrlCommand *)command;

@end
