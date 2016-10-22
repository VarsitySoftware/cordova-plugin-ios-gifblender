//
//  GIFBlender.m
//
//  Created by John Weaver on 10/22/2016
//

#import "GIFBlender.h"
#import <Accounts/Accounts.h>
#import <UIKit/UIKit.h>

@implementation GIFBlender 
@synthesize callbackId;

- (void) blend:(CDVInvokedUrlCommand *)command {
    
    NSDictionary *options = [command.arguments objectAtIndex: 0];
  
	  NSString * strFileURL = [options objectForKey:@"fileURL"];

    self.callbackId = command.callbackId;	
    
    NSLog(@"The GIF Blender");
    
}

@end
