//
//  JVMusicPlayer.h
//  JVMusicPlayer
//
//  Created by Jorge Valbuena on 2015-03-04.
//  Copyright (c) 2015 Jorge Valbuena. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Constants.h"

@interface JVMusicPlayer : UIView <MPPlayableContentDelegate, MPPlayableContentDataSource>

@property (strong, nonatomic) MPMusicPlayerController *mpMusicPlayer;
@property (strong, nonatomic) MPMediaItemCollection *userMediaItemCollection;

// Initializers
- (instancetype)init;
- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;

// Helper Functions
- (void)play;
- (void)pause;
- (void)stop;
- (void)next;
- (void)prev;

@end