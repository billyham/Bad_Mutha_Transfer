//
//  HAMDocument.h
//  Bad Mutha Transfer
//
//  Created by edit 6 on 7/22/12.
//  Copyright (c) 2012 nwfilm. All rights reserved.
//

#import <QTKit/QTKit.h>

// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>



@interface HAMDocument : NSDocument <NSOpenSavePanelDelegate> {
    
    QTCaptureSession* mCaptureSession;
    QTCaptureDeviceInput* mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput* mCaptureDecompressedVideoOutput;
    QTCaptureMovieFileOutput* mCaptureMovieFileOutput;
    
    QTCaptureView* mCaptureView;
    IBOutlet QTMovieView* mMovieView;
    QTMovie* mMovie;
    
    CVImageBufferRef	mCurrentImageBuffer;
    
    NSURL* destinationUrl;
    NSString* destinationName;
    
//    IBOutlet HAMPreviewWindowController* previewWindowController;
    
    IBOutlet NSTextField* totalFrames;
    IBOutlet NSTextField* frameCounterText;
    IBOutlet NSTextField* timerDuration;
    IBOutlet NSTextField* timerDelay;
    IBOutlet NSTextField* usbPath;
    
    //onOff button
    IBOutlet NSMatrix* onOffToggle;
    
    
    //serial comm
    int serialFileDescriptor; // file handle to the serial port
	struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
	NSTextStorage *storage;
    
}

@property (retain, nonatomic) QTCaptureSession* mCaptureSession;
@property (retain, nonatomic) QTCaptureDeviceInput* mCaptureDeviceInput;
@property (retain, nonatomic) QTCaptureDecompressedVideoOutput* mCaptureDecompressedVideoOutput;
@property (retain, nonatomic) QTCaptureMovieFileOutput* mCaptureMovieFileOutput;

@property (retain, nonatomic) IBOutlet QTCaptureView* mCaptureView;
@property (retain, nonatomic) IBOutlet QTMovieView* mMovieView;
@property (retain, nonatomic) QTMovie* mMovie;

@property CVImageBufferRef mCurrentImageBuffer;


@property (retain, nonatomic) NSURL* destinationUrl;
@property (retain, nonatomic) NSString* destinationName;

@property (retain, nonatomic) IBOutlet NSTextField* totalFrames;
@property (retain, nonatomic)  IBOutlet NSTextField* frameCounterText;
@property (retain, nonatomic)  IBOutlet NSTextField* timerDuration;
@property (retain, nonatomic) IBOutlet NSTextField* timerDelay;
@property (retain, nonatomic) IBOutlet NSTextField* usbPath;

@property (retain, nonatomic) IBOutlet NSMatrix* onOffToggle;


-(IBAction)resetTheUSBToArduinoConnection:(id)sender;
-(IBAction)addFrame:(id)sender;
-(IBAction)saveMovie:(id)sender;
-(IBAction)selectDestination:(id)sender;
-(IBAction)showPreview:(id)sender;
-(IBAction)hidePreview:(id)sender;
-(IBAction)advanceProjector:(id)sender;
-(IBAction)goGoBadMuthaTransfer:(id)sender;
-(IBAction)resetCounter:(id)sender;
-(IBAction)singleTrigger:(id)sender;



//serial comm methods
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void) writeByte: (uint8_t *) val;



@end
