//
//  GIFBlender.m
//
//  Created by John Weaver on 10/22/2016
//

#import "GIFBlender.h"
#import <Accounts/Accounts.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+animatedGIF.h"

@implementation GIFBlender 
@synthesize callbackId;
@synthesize webView;

- (void) blend:(CDVInvokedUrlCommand *)command 
{
	///////////////////////////////////////// 
	// SET VARS
	/////////////////////////////////////////

	self.callbackId = command.callbackId;	

    NSDictionary *options = [command.arguments objectAtIndex: 0];

	NSString * strURL = [options objectForKey:@"url"];
	NSString * strFilter = [options objectForKey:@"filter"];
	NSString * strCSSPath = [options objectForKey:@"cssPath"];
	NSString * strOverlayBase64 = [options objectForKey:@"overlayBase64"];
	NSString * strLoadDelay = [options objectForKey:@"overlayBase64"];

	int intQuality = [[options objectForKey:@"quality"] integerValue];

	//int intFrameCount;
	//int intFramesToUse;

	int intCounter = 0;
	int intFramesExtracted = 0;

	//int intGifWidth = 0;
	//int intGifHeight = 0;

	int intWebViewHeight = 0;

	int intScreenWidth = 0;
	int intScreenHeight = 0;

	///////////////////////////////////////// 
	// SET PIXEL DENSITY
	/////////////////////////////////////////
	
	self.pixelDensity = 2;

	///////////////////////////////////////// 
	// GET SCREEN SIZE
	/////////////////////////////////////////

	intScreenWidth = [[UIScreen mainScreen] bounds].size.width;
	intScreenHeight = [[UIScreen mainScreen] bounds].size.height;

	///////////////////////////////////////// 
	// SET LOAD DELAY
	/////////////////////////////////////////

	self.quality = intQuality;

	///////////////////////////////////////// 
	// SET LOAD DELAY
	/////////////////////////////////////////
	
	if (strLoadDelay != [NSNull null])		 			
	{
		self.loadDelay = [strLoadDelay floatValue];
	}
	else
	{
		self.loadDelay = 0.0;
	}

	///////////////////////////////////////// 
	// SET ROOT VIEW
	/////////////////////////////////////////
	
	self.rootView = [[[UIApplication sharedApplication] keyWindow] rootViewController].view;
	
	///////////////////////////////////////// 
	// SET LOCAL URL TO SAVE FILE FROM REMOTE
	/////////////////////////////////////////

	NSURL* remoteURL = [NSURL URLWithString:strURL];   
	self.localURL = [self saveLocalFileFromRemoteUrl: remoteURL extension:@"gif"]; 

	///////////////////////////////////////// 
	// SET ANIMATED GIF PATH
	/////////////////////////////////////////

	NSString *strGIFPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"animated.gif"];
   
	///////////////////////////////////////// 
	// CREATE UIMAGE FROM ANIMATED GIF (UIImage+animatedGIF.h)
	/////////////////////////////////////////

	UIImage * imgWithAnimation = [UIImage animatedImageWithAnimatedGIFURL:(NSURL *)self.localURL];

	///////////////////////////////////////// 
	// GET DIMENSIONS
	/////////////////////////////////////////

	self.gifWidth = imgWithAnimation.size.width;
	self.gifHeight = imgWithAnimation.size.height;

	///////////////////////////////////////// 
	// SET FRAME COUNT
	/////////////////////////////////////////

	self.numberOfFramesTotal = [imgWithAnimation.images count];
	self.numberOfFramesToUse = (self.numberOfFramesTotal / 10) + 1;

	NSLog(@"# of Frames: %i; # to use: %i", self.numberOfFramesTotal, self.numberOfFramesToUse);

	///////////////////////////////////////// 
	// GET OVERLAY
	/////////////////////////////////////////

	if (strOverlayBase64 != [NSNull null])		 			
	{
		NSData *datOverlayBase64 = [[NSData alloc]initWithBase64EncodedString:strOverlayBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];	
		self.imageOverlay = [UIImage imageWithData:datOverlayBase64];
	}

	///////////////////////////////////////// 
	// BUILD HTML STRING
	/////////////////////////////////////////

	NSString *HTML_HEADER=@"<HTML><HEAD><link rel='stylesheet' href='#CSS#' type='text/css'></HEAD>";
	NSString *cssFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:strCSSPath];		
	NSString* strCSS = [NSString stringWithContentsOfFile:cssFilePath encoding:NSUTF8StringEncoding error:NULL];
	NSString *HTML_HEADER_WITH_CSS = [HTML_HEADER stringByReplacingOccurrencesOfString:@"#CSS#" withString:cssFilePath];
	NSMutableString *html = [NSMutableString stringWithString: @""];
	NSLog(@"HTML %@", HTML_HEADER_WITH_CSS);
	[html appendString:@"<html>"];
	[html appendString:@"<head>"];
	[html appendString:@"<title></title>"];
	[html appendString:@"<style>"];
	[html appendString:strCSS];
	[html appendString:@"</style>"];
	[html appendString:@"</head>"];
	[html appendString:@"<body style=\"background:transparent; padding:0px; margin:0px;\">"];

	if (strFilter != [NSNull null])		 			
	{
		[html appendString:@"<div class='"];
		[html appendString:strFilter];
		[html appendString:@"'>"];
	}
	else
	{
		[html appendString:@"<div>"];
	}		
	
	///////////////////////////////////////// 
	// EXTRACT FRAMES FROM GIF
	/////////////////////////////////////////

	for (int i = 0; i < self.numberOfFramesTotal; i++)
	{		
		if (intCounter == 0)
		{
			UIImage * img = imgWithAnimation.images[i];
			
			NSString * base64String = [UIImagePNGRepresentation(img) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

			[html appendString:@"<div>"];
			[html appendString:@"<img src='data:image/jpeg;base64,"];
			[html appendString:base64String];
			[html appendString:@"'>"];
			[html appendString:@"</div>"];
			//[html appendString:@"<span style='color:#fff;'>"];
			//[html appendString:[NSString stringWithFormat:@"%i", intFramesExtracted]];		
			//[html appendString:@"</span>"];

			intFramesExtracted++;
		}

		intCounter++;

		if (intCounter >= 10)
		{
			intCounter = 0;
		}
	}	

	///////////////////////////////////////// 
	// FINISH BUILDING HTML STRING
	/////////////////////////////////////////

	[html appendString:@"</div>"];	
    [html appendString:@"</body></html>"];

	///////////////////////////////////////// 
	// CREATE WEBVIEW FROM HTML STRING
	// SET POS Y TO SCREEN HEIGHT SO IT SHOWS BELOW THE FOLD
	/////////////////////////////////////////
	
	self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, intScreenHeight, self.gifWidth, intScreenHeight)]; 	
	self.webView.delegate = self;
	[self.webView loadHTMLString:[html description] baseURL:nil];

	///////////////////////////////////////// 
	// ADD WEBVIEW TO ROOT VIEW
	/////////////////////////////////////////
	
	[self.rootView addSubview:self.webView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

	NSLog(@"Webview loading finished");

	///////////////////////////////////////// 
	// DELAY THE NEXT STEP IN ORDER TO GIVE IMAGES CHANCE TO LOAD
	/////////////////////////////////////////

	[self performSelector:@selector(webViewLoaded) withObject:nil afterDelay: self.loadDelay];    
}

 - (void)webViewLoaded;
 {
	NSLog(@"Webview is definitely finished loading");	
	
	///////////////////////////////////////// 
	// SET VARS
	/////////////////////////////////////////

	int intPosY = 0;

	int intCropWidth = self.gifWidth * self.pixelDensity;
	int intCropHeight = self.gifHeight * self.pixelDensity;

	int intOutputWidth = self.gifWidth;
	int intOutputHeight = self.gifHeight;
	
	unsigned long long fileSize = 0;

	///////////////////////////////////////// 
	// SET GIF PATH
	/////////////////////////////////////////

	NSString *strAnimatedGIFPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"animated.gif"];
  
	///////////////////////////////////////// 
	// GET SCREENSHOT
	/////////////////////////////////////////

	UIImage * imgScreenShot = [self imageFromWebView: self.webView]; 
	
	///////////////////////////////////////// 
	// SET QUALITY
	/////////////////////////////////////////
	
	if (self.quality < 100)
	{
		float fltQuality = self.quality / 100.0;
		float fltOutputWidth = self.gifWidth * fltQuality;
		float fltOutputHeight = self.gifHeight * fltQuality;

		intOutputWidth = (int) fltOutputWidth;
		intOutputHeight = (int) fltOutputHeight;		
	}

	///////////////////////////////////////// 
	// SET OUTPUT SIZE
	/////////////////////////////////////////
	
	CGSize scaledSize = CGSizeMake(intOutputWidth, intOutputHeight);
	
	///////////////////////////////////////// 
	// SET GIF PROPERTIES
	/////////////////////////////////////////

	NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:
		[NSDictionary  dictionaryWithObject:[NSNumber numberWithInt:0.0]  
		forKey:(NSString *) kCGImagePropertyGIFDelayTime] 
		forKey:(NSString *) kCGImagePropertyGIFDictionary];

	NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:
		[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]
         forKey:(NSString *) kCGImagePropertyGIFLoopCount]
		forKey:(NSString *) kCGImagePropertyGIFDictionary];
	  
    ///////////////////////////////////////// 
	// CREATE IMAGE DESTINATION
	/////////////////////////////////////////

	CGImageDestinationRef animatedGIF = CGImageDestinationCreateWithURL(
       (CFURLRef) [NSURL fileURLWithPath:strAnimatedGIFPath],
       kUTTypeGIF,
       self.numberOfFramesToUse, // number of images in this GIF
       NULL);
	
	///////////////////////////////////////// 
	// GET FRAMES
	/////////////////////////////////////////
	
	for (int i = 0; i < self.numberOfFramesToUse; i++) 
	{
		///////////////////////////////////////// 
		// SET CROP RECTANGLE - MOVES DOWN PAGE WITH EVERY ITERATION
		/////////////////////////////////////////	

		CGRect rectCrop = CGRectMake(0, intPosY, intCropWidth, intCropHeight); // or whatever rectangle

		///////////////////////////////////////// 
		// CREATE IMAGE REF
		/////////////////////////////////////////	
		
		CGImageRef drawImage = CGImageCreateWithImageInRect([imgScreenShot CGImage], rectCrop);
		
		///////////////////////////////////////// 
		// CUT OUT NEXT FRAME FROM PAGE FULL OF FRAMES
		/////////////////////////////////////////	
		
		UIImage *imgFrame = [UIImage imageWithCGImage:drawImage];
		
		///////////////////////////////////////// 
		// RELEASE IMAGE REF
		/////////////////////////////////////////	
		
		CGImageRelease(drawImage);

		///////////////////////////////////////// 
		// ADD OVERLAY TO FRAME
		/////////////////////////////////////////	
		
		UIImage * imgResult = [self combineImages:self.imageOverlay backgroundImage:imgFrame scaledToSize: scaledSize]; 

		///////////////////////////////////////// 
		// ADD IMAGE TO DESTINATION
		/////////////////////////////////////////

		CGImageDestinationAddImage(animatedGIF, imgResult.CGImage, (CFDictionaryRef)frameProperties);
		
		///////////////////////////////////////// 
		// MOVE Y POS TO NEXT IMAGE
		/////////////////////////////////////////

		intPosY += intCropHeight;
	}	

	///////////////////////////////////////// 
	// FINALIZE IMAGE DESTINATION
	/////////////////////////////////////////

	CGImageDestinationSetProperties(animatedGIF, (CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(animatedGIF);
	CFRelease(animatedGIF);
	
	///////////////////////////////////////// 
	// GET FILE SIZE
	/////////////////////////////////////////
	
	fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:strAnimatedGIFPath error:nil] fileSize];
	NSString *strFileSize = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
 
	///////////////////////////////////////// 
	// SEND RESULT BACK TO CORDOVA
	/////////////////////////////////////////

	self.jsonResults = [ [NSMutableDictionary alloc]
        initWithObjectsAndKeys :
		nil, @"filePath",        
		nil, @"fileSize",        
        nil
    ]; 

	self.jsonResults[@"filePath"] = strAnimatedGIFPath;	
	self.jsonResults[@"fileSize"] = strFileSize;	

	self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.jsonResults];	

	[self.pluginResult setKeepCallbackAsBool:NO]; // here we tell Cordova not to cleanup the callback id after sendPluginResult()					
	[self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.callbackId];		
	
	//NSLog(@"animated GIF file created at %@", strAnimatedGIFPath);

 } 
 
 -(void *)preview;
{
	///////////////////////////////////////// 
	// SEND RESULT BACK TO CORDOVA
	/////////////////////////////////////////

	UIWebView *preview =[[UIWebView alloc] initWithFrame:CGRectMake(0, 350, self.gifWidth, self.gifHeight)]; 	

	NSMutableString *html = [NSMutableString stringWithString: @""];

	[html appendString:@"<html>"];
	[html appendString:@"<head>"];
	[html appendString:@"<title></title>"];	
	[html appendString:@"</head>"];
	[html appendString:@"<body style=\"background:transparent; padding:0px; margin:0px;\">"];

	[html appendString:@"<img style='width:320px;' src='"];    
	//[html appendString:[NSString stringWithFormat:@"file://%@", strAnimatedGIFPath]];     
	[html appendString:@"'/>"];    	
    [html appendString:@"</body></html>"];

	NSLog(@"html: %@", html);

	[preview loadHTMLString:[html description] baseURL:nil];
	[self.rootView addSubview:preview];
}

-(NSData *)imageFromWebView:(UIView *)view  // Mine is UIWebView but should work for any
{
	int intScreenWidth = [[UIScreen mainScreen] bounds].size.width;
	int intScreenHeight = [[UIScreen mainScreen] bounds].size.height;

    NSData *pngImg;
    CGFloat max, scale = 2.0;
    CGSize viewSize = [view bounds].size;

    // Get the size of the the FULL Content, not just the bit that is visible
    CGSize size = [view sizeThatFits:CGSizeZero];

    // Scale down if on iPad to something more reasonable
    max = (viewSize.width > viewSize.height) ? viewSize.width : viewSize.height;
    if( max > 960 )
	{
        scale = 960/max;
	}

    UIGraphicsBeginImageContextWithOptions( size, YES, scale );

    // Set the view to the FULL size of the content.
	// HAVE IT BE BELOW FOLD!
    [view setFrame: CGRectMake(0, intScreenHeight, size.width, size.height)];

    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];    
    pngImg = UIImagePNGRepresentation( UIGraphicsGetImageFromCurrentImageContext() );
	
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    //return pngImg;    // Voila an image of the ENTIRE CONTENT, not just visible bit
	return image;
}

- (UIImage *) combineImages:(UIImage *)foregroundImage backgroundImage:(UIImage *)backgroundImage scaledToSize:(CGSize)scaledSize
{
	//NSLog(@"backgroundImage.size.width: %f", backgroundImage.size.width);
	//NSLog(@"backgroundImage.size.height: %f", backgroundImage.size.height);
	//NSLog(@"scaledSize.size.width: %f", scaledSize.width);
	//NSLog(@"scaledSize.size.height: %f", scaledSize.height);

	////////////////////

	//UIGraphicsBeginImageContext(backgroundImage.size);	
	//[backgroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
	//[foregroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];

	UIGraphicsBeginImageContextWithOptions(scaledSize, YES, 1.0); 
	[backgroundImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
	[foregroundImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
	
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return result;
}

- (NSURL*)saveLocalFileFromRemoteUrl:(NSURL*)url extension:(NSString *)extension
{   
    if (!NSTemporaryDirectory())
    {
       // no tmp dir for the app (need to create one)
    }

    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    //NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"temp"] URLByAppendingPathExtension:@"mp4"];
	NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"temp"] URLByAppendingPathExtension:extension];
    
	NSData *urlData = [NSData dataWithContentsOfURL:url];
    [urlData writeToURL:fileURL options:NSAtomicWrite error:nil];

	NSLog(@"fileURL: %@", [fileURL path]);

	return fileURL;
}

@end
