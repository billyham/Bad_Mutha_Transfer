//
//  HAMDocument.m
//  Bad Mutha Transfer
//
//  Created by edit 6 on 7/22/12.
//  Copyright (c) 2012 nwfilm. All rights reserved.
//

#import "HAMDocument.h"


@interface HAMDocument()


-(void)triggerAction;
-(void)continueTransfer;


@end


@implementation HAMDocument

@synthesize mCaptureSession;
@synthesize mCaptureDeviceInput;
@synthesize mCaptureDecompressedVideoOutput;
@synthesize mCaptureMovieFileOutput;

@synthesize mCaptureView;
@synthesize mMovieView;
@synthesize mMovie;

@synthesize mCurrentImageBuffer;

@synthesize destinationUrl;
@synthesize destinationName;

@synthesize totalFrames;
@synthesize frameCounterText;
@synthesize timerDuration;
@synthesize timerDelay;
@synthesize usbPath;

@synthesize onOffToggle;

@synthesize dictionaryOfFilters;
@synthesize invertColorButton;

@synthesize gammaValue;

int frameCounter;
int onOffState;


- (id)init
{
    self = [super init];
    if (self) {
        
        frameCounter = 0;
        onOffState = 0;
        
        destinationName = @"badmutha";
                
        
    }
    return self;
}

- (NSString *)windowNibName
{
    
    return @"HAMDocument";
}


#pragma mark - methods


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    
    //set gamma
    self.gammaValue = [NSNumber numberWithFloat:0.75];
    
    //set user defaults
    NSDictionary* usbPathDefault = [NSDictionary dictionaryWithObject:@"/dev/cu.usbserial-A600494p" forKey:@"usbPathDefault"];
    
    NSDictionary* appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 usbPathDefault, @"usbPathDefault",
                                 nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    
    QTCaptureDevice *theDefaultMuxedDevice; 
    QTCaptureDeviceInput *theDeviceInput; 
    BOOL success; 
    NSError* error = nil;

    // get the default muxed device
    
    
    theDefaultMuxedDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
    
    // open the device 
    
    success = [theDefaultMuxedDevice open:&error]; 
    if (YES == success) {
        
        NSLog(@"found muxed device affirmative!");
        
        // create and associate device input
        
        theDeviceInput = [QTCaptureDeviceInput deviceInputWithDevice:theDefaultMuxedDevice];
        
        // get the list of owned connections 
        
        NSArray *ownedConnections = [theDeviceInput connections];
        
        // disable all the audio connections 
        
        for (QTCaptureConnection *connection in ownedConnections) {
            
            if ( [[connection mediaType] isEqualToString:QTMediaTypeSound] ) { 
                
                [connection setEnabled:NO];
            }
            
        }
        
        NSLog(@"list of owned connections: %u", [ownedConnections count]);
        
    } else {
        
    }
    
    
    //create an empty movie that writes to mutable data in memory
    
    [super windowControllerDidLoadNib:aController];
    [[aController window] setDelegate:(id)self];
    
    if (!mMovie) {
        mMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error];
        
        if (!mMovie) {
            [[NSAlert alertWithError:error] runModal];
            
        }
    }
    
    
    //__________________
    
    
    //create the movie file output and add it to the session
    mCaptureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
    success = [mCaptureSession addOutput:mCaptureMovieFileOutput error:&error];
    
    if (!success) { 
        
    } 
    
    [mCaptureMovieFileOutput setDelegate:self];
    
    //Specify the compression options with an identifier with a size for video and a quality for audio.
    
    NSEnumerator *connectionEnumerator = [[mCaptureMovieFileOutput connections] objectEnumerator];
    QTCaptureConnection *connection;
    while ((connection = [connectionEnumerator nextObject])) { 
        
        NSString *mediaType = [connection mediaType]; 
        
        QTCompressionOptions *compressionOptions = nil; 
        
        if ([mediaType isEqualToString:QTMediaTypeVideo]) {
            compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions240SizeH264Video"];
            
        } else if ([mediaType isEqualToString:QTMediaTypeSound]) {
            
            compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsHighQualityAACAudio"];
        }
        
        [mCaptureMovieFileOutput setCompressionOptions:compressionOptions forConnection:connection];
    }
        
        //___________________________
    
    
    
    //______________internal preview window_____________**********
    //set up a capture session that outputs raw frames you want to grab
    [mMovieView setMovie:mMovie];
    
    
    if (!mCaptureSession) {
        BOOL success;
        mCaptureSession = [[QTCaptureSession alloc] init];
        
        //find a video device and add a device input for that device to the capture session
//        QTCaptureDevice* device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        
//        success = [device open:&error];
//        
//        if (!success) {
//            [[NSAlert alertWithError:error] runModal];
//            return;
//        }
        
//        mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        //or rather than the isight camera, use the dv camera
        mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:theDefaultMuxedDevice];
        
        success = [mCaptureSession addInput:mCaptureDeviceInput error:&error];
        
        if (!success) {
            
            [[NSAlert alertWithError:error] runModal];
            
            return;
        }
        
        //add a decompressed video output that returns the raw frames you've grabbed to the session and then
        //previews the video from the session in the doc window
        
        mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
        
        [mCaptureDecompressedVideoOutput setDelegate:self];
        
        success = [mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error];
        
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
        
        //preview the video from the session in the doc window
        [mCaptureView setCaptureSession:mCaptureSession];
        
        
        //_____start the session, using the startRunning method you've used previously in the myRecorder sample code
        
        [mCaptureSession startRunning];
        
    }
    
    //______________initialize preview window_____________************
//    self.previewWindowController = [[HAMPreviewWindowController alloc] initWithWindowNibName:@"HAMPreviewWindowController"];
//    
//    //set up a capture session that outputs raw frames you want to grab
//    [self.previewWindowController.altMovieView setMovie:mMovie];
    
    
    
    [mMovieView setHidden:YES];    
    
    [super windowControllerDidLoadNib:aController];
    
    
    
    
    //initial field values
    self.timerDuration.stringValue = @"1.19";
    self.timerDelay.stringValue = @"0.0";
    self.frameCounterText.stringValue = @"0";
    self.totalFrames.stringValue = @"10";
    
    //get default usbpath from user defaults
//    self.usbPath.stringValue = @"/dev/cu.usbserial-A600494p";
    self.usbPath.stringValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"usbPathDefault"] objectForKey:@"usbPathDefault"];
    
    
    //___________________serial comm setup_____________****************
    // we don't have a serial port open yet
	serialFileDescriptor = -1;
	readThreadRunning = FALSE;
	
	// first thing is to refresh the serial port list
//	[self refreshSerialList:@"Select a Serial Port"];
    
    NSString* serialPortHardWired = self.usbPath.stringValue;
    NSString *shozbot = [self openSerialPort: serialPortHardWired baud:9600];

    if (shozbot) {
        NSLog(@"this is shozbot: %@  this is serialFileDescriptor: %u", shozbot, serialFileDescriptor);
    }
    
    //prompt user to enter the initial destination
    [self performSelector:@selector(selectDestination:) withObject:nil afterDelay:1.0];
    
    
    //build dictionary of available image filters
    [self buildDictionaryOfFilters];
    

}


-(IBAction)resetTheUSBToArduinoConnection:(id)sender{
    
    serialFileDescriptor = -1;
	readThreadRunning = FALSE;
    
    NSString *shozbot = [self openSerialPort:self.usbPath.stringValue baud:9600];
    
    //save to defaults
    NSDictionary* newUsbDic = [NSDictionary dictionaryWithObject:self.usbPath.stringValue forKey:@"usbPathDefault"];
    [[NSUserDefaults standardUserDefaults] setObject:newUsbDic forKey:@"usbPathDefault"];
    
    if (shozbot) {
        NSLog(@"this is shozbot: %@  this is serialFileDescriptor: %u", shozbot, serialFileDescriptor);
    }
    
}


//implement a delegate method that QTCaptureDecompressedVideoOutput calls whenever it receives a frame
-(void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection{
    
    //store the latest frame. Do this in a @synchronized block because the delegate method is not called on the main
    //thread
    CVImageBufferRef imageBufferToRelease;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        
        imageBufferToRelease = mCurrentImageBuffer;
        
        mCurrentImageBuffer = videoFrame;
    }
    
    CVBufferRelease(imageBufferToRelease);
    
}

//handle window closing notifications for your device input and stop the capture session
-(void)windowWillClose:(NSNotification*)notification{
    
    [mCaptureSession stopRunning];
    
    QTCaptureDevice* device = [mCaptureDeviceInput device];
    
    if ([device isOpen])
        [device close];
    
}



#pragma mark - I don't think these are ever called, sure wish they were

//specify the output destination for your recorded media, in this case editable QuickTime movie
-(BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    
    NSLog(@"readFromURL called");
    
    QTMovie* newMovie = [[QTMovie alloc] initWithURL:absoluteURL error:outError];
    
    if (newMovie) {
        [newMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
        
        [mMovie release];
        
        mMovie = newMovie;
    }
    
    return (newMovie != nil);
}

-(BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    
    NSLog(@"write to file url called with: %@", [absoluteURL path]);
    
    return [mMovie writeToFile:[absoluteURL path] withAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten] error:outError];
    
}



#pragma mark - Record still frame

//add the addFrame: action
//This enables you to get the most recent frame that you’ve grabbed. Do this in a @synchronized block because the delegate method that 
//sets the most recent frame is not called on the main thread. Note that you’re wrapping a CVImageBufferRef object into an NSImage. After 
//you create an NSImage, you can then add it to the movie.
-(IBAction)addFrame:(id)sender{
    
    CVImageBufferRef imageBuffer;
    
    //NSData is somehow a necessary step for 64 bit mode. a project for later.
//    NSData* mData = [NSData alloc] ini
    
    @synchronized (self) {
        
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);
    }
    
    if (imageBuffer) {
        
        //assign options that provide correct size
//        NSNumber *pixelRatio = [NSNumber numberWithFloat:2.0];
//        NSDictionary *pixelAspectRatio = [NSDictionary dictionaryWithObjectsAndKeys:
//                                          pixelRatio, kCVImageBufferPixelAspectRatioHorizontalSpacingKey, 
//                                          pixelRatio, kCVImageBufferPixelAspectRatioVerticalSpacingKey, 
//                                          nil];
//        
//        NSDictionary* myDic = [NSDictionary dictionaryWithObjectsAndKeys: 
//                               
//                               pixelAspectRatio, kCVImageBufferPixelAspectRatioKey,
//                               [NSNumber numberWithLong:CVPixelBufferGetWidth (mCurrentImageBuffer)], kCVImageBufferCleanApertureWidthKey, 
//                               [NSNumber numberWithLong:CVPixelBufferGetHeight (mCurrentImageBuffer)], kCVImageBufferCleanApertureHeightKey, 
//                               
//                               nil];
//        
        
        
//        NSCIImageRep* imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer options:myDic]];
        
        
        //rotate the image 180 degrees
        
        
        CIImage* initialImage = [CIImage imageWithCVImageBuffer:imageBuffer];
        
        CIImage* rotatedImage = [initialImage imageByApplyingTransform:CGAffineTransformMakeRotation(3.1416)]; 
        
        NSCIImageRep* imageRep = [NSCIImageRep imageRepWithCIImage:rotatedImage];
        
        //successfully create image without rotating it by deleting above lines and replacing with this
//        NSCIImageRep* imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];


        
        if (nil == imageRep) NSLog(@"imageRep is nil");
        
        NSImage* image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
        
        
        if (nil == image) NSLog(@"image is nil");

        
 
        
        
        
        
        
        //THIS ONLY APPLIES TO THE PREVIEW, IT DOESN'T AFFECT THE RAW FILE SAVED
        //only imageRep is given to the raw file
        
        [image addRepresentation:imageRep];
        
        
        
        
        
        //____________RESIZE NSIMAGE, EXCEPT NSIMAGE IS NOT THE OBJECT USED AS A RAW FRAME 
//        NSSize size = NSZeroSize;      
//        size.width = image.size.width*0.5;
//        size.height = image.size.height*0.5; 
//        
//        NSImage *ret = [[NSImage alloc] initWithSize:size];
//        [ret lockFocus];
//        NSAffineTransform *transform = [NSAffineTransform transform];
//        [transform scaleBy:0.5];  
//        [transform concat]; 
//        [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];    
//        [ret unlockFocus];        
//        

        
        
        
        
//        [ret addRepresentation:imageRep];

        
        
        //_____
        //resize image to correct aspect ratio and standard file size
        //720 x 1280, 1080 x 1920 or 480 x 720
//        NSRect thisRect = NSMakeRect(0.0, 0.0, 1280.0, 720.0);
//                            
//        struct CGImageRef* thisCGImageRef = [image CGImageForProposedRect:&thisRect context:nil hints:nil];
//        
//        CFURLRef bottlebogs = destinationUrl;
//        
//        CGImageDestinationRef hotDogs = CGImageDestinationCreateWithURL (
//                                                               bottlebogs,
//                                                               kUTTypePNG,
//                                                               1,
//                                                                         nil);

        
        //_____THIS DOESN'T WORK
        //resize and save image file
//        NSRect resizedBounds = NSMakeRect(0, 0, 1280, 720);
//        NSImage* resizedImage = [[[NSImage alloc] initWithSize:resizedBounds.size]
//                                autorelease];
//        
//        [resizedImage lockFocus];
//        [image drawInRect:resizedBounds fromRect:NSZeroRect
//                       operation:NSCompositeCopy fraction:1.0];
//        [resizedImage unlockFocus];
//        
//        
//        
////        NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithCIImage:[imageRep CIImage]];
//        NSBitmapImageRep *imgRep = [[resizedImage representations] objectAtIndex:0];
//        
//        if (nil == imgRep) NSLog(@"poopy pants");
//        
//        
//        
//        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
//        
//         //destination for individual frames, using counter
//        NSString* destination = [NSString stringWithFormat:@"%@/%@%u.png", [destinationUrl path], destinationName, frameCounter];
//        
//        [data writeToFile: destination atomically: NO];
//
        
        //declare to reference in if statement
        NSBitmapImageRep* imgRep;
        
        
        NSLog(@"this is the current gamma: %@", self.gammaValue);
        
        //_______read gamma slider and act accordingly  (default value is .75)
        CIFilter* gammaFilter = [CIFilter filterWithName:@"CIGammaAdjust"];
        [gammaFilter setValue:[imageRep CIImage] forKey:@"inputImage"];
        [gammaFilter setValue:[NSNumber numberWithFloat:[self.gammaValue floatValue]] forKey:@"inputPower"];
        CIImage* gammaAdjustedImage = [gammaFilter valueForKey:@"outputImage"];
        
        
        //NO! this doesnt work
        //______Resized CIImage
//        CGAffineTransform sizeTransform = CGAffineTransformMakeTranslation(0.0,1080.f);
//        sizeTransform = CGAffineTransformScale(sizeTransform, 1.5, 1.0);
//        CIImage *sizeAdjustedImage = [gammaAdjustedImage imageByApplyingTransform:sizeTransform];
//        
//        
        
        
        
        
        //______read invertColor button and act accordingly
        if (self.invertColorButton.state == 1){
            
            //____________________invert image color
            //http://stackoverflow.com/questions/2137744/draw-standard-nsimage-inverted-white-instead-of-black
            //
            CIFilter* filter = [CIFilter filterWithName:@"CIColorInvert"];
            [filter setDefaults];
            [filter setValue:gammaAdjustedImage forKey:@"inputImage"];
            CIImage* outputImage = [filter valueForKey:@"outputImage"];
            
            //____this draws to screen, which we don't want. At least not as it is here.
            //        [outputImage drawAtPoint:NSZeroPoint fromRect:NSRectFromCGRect([outputImage extent]) operation:NSCompositeSourceOver fraction:1.0];
            
            imgRep = [[[NSBitmapImageRep alloc] initWithCIImage:outputImage] autorelease];

        }else{
            
            imgRep = [[[NSBitmapImageRep alloc] initWithCIImage:gammaAdjustedImage] autorelease];
            
        }
        
        
        
        
        
        //____________________save individual files to disk

        
        //______THIS WORKS BUT LEAVES THE IMAGE AT ITS RAW SIZE AND WRONG ASPECT RATIO
//        [imgRep setSize:NSMakeSize(1280.0, 720.0)];  // <--- if left alone, doesn't resample, but changes dpi and size proportionally

        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
        
        //destination for individual frames, using counter
        NSString* destination = [NSString stringWithFormat:@"%@/%@%u.png", [destinationUrl path], destinationName, frameCounter];
        
        [data writeToFile: destination atomically: NO];
        
        
        
//        imgRep = nil;
//        [imgRep release];
        
        data = nil;
        [data release];
        
        
        
        
        //________        
        
        //advance the counter
        frameCounter += 1; 
        
        

        
        
        
        
        
        
        CVBufferRelease(imageBuffer);
        

        
        //________
        //add to inline preview movie
//        
//        [mMovie addImage:image forDuration:QTMakeTime(1, 10) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                                             @"jpeg", QTAddImageCodecType, nil]];
//
//        
//        [mMovie setCurrentTime:[mMovie duration]];
//        
//        //______________internal preview window____________*********
//        [mMovieView setNeedsDisplay:YES];
//        
//        [self updateChangeCount:NSChangeDone];
//        //__________
        
        
        
        
//        image = nil;
//        [image release];
        
    }
    
}


#pragma mark - CIFilters

-(void)buildDictionaryOfFilters{
    
    self.dictionaryOfFilters = [NSMutableDictionary dictionary];
    
    NSMutableArray *filterNames = [NSMutableArray array];
    [filterNames addObjectsFromArray:
     [CIFilter filterNamesInCategory:kCICategoryColorAdjustment]];
    [filterNames addObjectsFromArray:
     [CIFilter filterNamesInCategory:kCICategoryColorEffect]];
    self.dictionaryOfFilters[@"Color"] = [self buildFilterDictionary: filterNames];
    
//    [filterNames removeAllObjects];
//    [filterNames addObjectsFromArray:
//     [CIFilter filterNamesInCategory:kCICategorySharpen]];
//    [filterNames addObjectsFromArray:
//     [CIFilter filterNamesInCategory:kCICategoryBlur]];
//    filtersByCategory[@"Focus"] = [self buildFilterDictionary: filterNames];
    
}


- (NSMutableDictionary *)buildFilterDictionary:(NSArray *)filterClassNames  // 1
{
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    for (NSString *className in filterClassNames) {                         // 2
        CIFilter *filter = [CIFilter filterWithName:className];             // 3
        
        if (filter) {
            filters[className] = [filter attributes];                       // 4
            NSLog(@"This is a color filter: %@", className);
        } else {
            NSLog(@"could not create '%@' filter", className);
        }
    }
    return filters;
}


#pragma mark - Preview movie

-(IBAction)showPreview:(id)sender{
    
    [mMovieView setHidden:NO];
}

-(IBAction)hidePreview:(id)sender{
    
    [mMovieView setHidden:YES];    
    
    
}


#pragma mark - Saving Movie

-(IBAction)saveMovie:(id)sender{
    
    BOOL yup = [mMovie canUpdateMovieFile];
    
    NSLog(@"can I ring your bell?  %u", yup);
    
    
}

-(IBAction)selectDestination:(id)sender{
    
    NSSavePanel* mySavePanel = [NSSavePanel savePanel];
    
    [mySavePanel setDelegate:(id)self];
    
    [mySavePanel setCanCreateDirectories:YES];
    
    [mySavePanel setTitle:@"Destination"];
    [mySavePanel setNameFieldLabel:@"File prefix"];
    [mySavePanel setNameFieldStringValue:@"frame"];
    [mySavePanel setMessage:@"Select a destination folder and enter a prefix for the file names"];
    
    [mySavePanel runModal];
    
}


#pragma mark - openSavePanel delegate methods

- (void)panel:(id)sender didChangeToDirectoryURL:(NSURL *)url{

//    NSLog(@"save panel delegate called: %@",url);
    
    self.destinationUrl = url;
}


- (NSString *)panel:(id)sender userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag{
    
    if (okFlag == YES) {
        self.destinationName = filename;
    }
        
    return filename;
}


#pragma mark - automation


-(IBAction)singleTrigger:(id)sender{
    
    //advance capture
    [self addFrame:nil];
    
    //advance counter
    self.frameCounterText.stringValue = [NSString stringWithFormat:@"%u", frameCounter];

    
}



-(IBAction)goGoBadMuthaTransfer:(id)sender{
        
    if ([[sender selectedCell] tag] == 2){
        
        //stop transferring
        onOffState = 0;
        
    } else {
        
        //start transferring
        onOffState = 1;
        
        [self continueTransfer];
    }
    
    
}


-(void)continueTransfer{
    
    //check state of onOff switch. Only proceed when on
    
    if (onOffState == 1) {
        
        //convert text field to integer for total frames
        int totalFramesInt = [totalFrames.stringValue intValue];
        
        if (frameCounter < totalFramesInt) {
            
            [self triggerAction];
            
            self.frameCounterText.stringValue = [NSString stringWithFormat:@"%u", frameCounter];
            
        } else {
            
            //turn toggle switch to off
            [onOffToggle selectCellWithTag:2];
            
        }
    }
    
}


-(void)triggerAction{
    
    //check state of onOff switch. Only proceed when on
    
    if (onOffState == 1) {
        
        float myTimer = [timerDuration.stringValue floatValue];
        
        [self addFrame:nil];
        
        float timerDurationFloat = [self.timerDelay floatValue];
        
        [self performSelector:@selector(advanceProjector:) withObject:nil afterDelay:timerDurationFloat];
        
        [self performSelector:@selector(continueTransfer) withObject:nil afterDelay:myTimer];
        
    }
    
}


-(IBAction)resetCounter:(id)sender{
    
    self.frameCounterText.stringValue = @"0";
    
    frameCounter = 0;
    
    //prompt user to select new destion folder since it will over write existing files
    [self selectDestination:nil];

    
}


#pragma mark - Projector connection

-(IBAction)advanceProjector:(id)sender{
    
//    NSLog(@"firing projector");
    
    uint8_t val = 7;
    [self writeByte:&val];
    
    
}


// send a byte to the serial port
- (void) writeByte: (uint8_t *) val {
	if(serialFileDescriptor!=-1) {
		write(serialFileDescriptor, val, 1);
	} else {
		NSLog(@"writeByte fails");
	}
}


// open the serial port
//   - nil is returned on success
//   - an error message is returned otherwise
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate {
	int success;
	
	// close the port if it is already open
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (serialFileDescriptor == -1) { 
		// check if the port opened correctly
		errorMessage = @"Error: couldn't open serial port";
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) { 
			errorMessage = @"Error: couldn't obtain lock on serial port";
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) { 
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = @"Error: couldn't obtain lock on serial port";
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) { 
					errorMessage = @"Error: couldn't get serial attributes";
				} else {
					// copy the old termios settings into the current
					//   you want to do this so that you get all the control characters assigned
					options = gOriginalTTYAttrs;
					
					/*
					 cfmakeraw(&options) is equivilent to:
					 options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
					 options->c_oflag &= ~OPOST;
					 options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
					 options->c_cflag &= ~(CSIZE | PARENB);
					 options->c_cflag |= CS8;
					 */
					cfmakeraw(&options);
					
					// set tty attributes (raw-mode in this case)
					success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
					if ( success == -1) {
						errorMessage = @"Error: coudln't set serial attributes";
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) { 
							errorMessage = @"Error: Baud Rate out of bounds";
						} else {
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) { 
								errorMessage = @"Error: coudln't set serial latency";
							}
						}
					}
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	return errorMessage;
}






#pragma mark - dealloc


//deallocate memory for your capture objects
-(void) dealloc {
    
    [mMovie release];
    [mCaptureSession release];
    [mCaptureDeviceInput release];
    [mCaptureDecompressedVideoOutput release];
    [super dealloc];
}































@end
