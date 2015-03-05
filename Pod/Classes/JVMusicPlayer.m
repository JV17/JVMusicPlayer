//
//  JVMusicPlayer.m
//  JVMusicPlayer
//
//  Created by Jorge Valbuena on 2015-03-04.
//  Copyright (c) 2015 Jorge Valbuena. All rights reserved.
//

#import "JVMusicPlayer.h"


#pragma mark - Interface
@interface JVMusicPlayer()

@property (strong, nonatomic) UISlider *slider;
@property (strong, nonatomic) NSTimer *currentTimer;
@property (strong, nonatomic) UIButton *btnPlay;
@property (strong, nonatomic) UIButton *btnNext;
@property (strong, nonatomic) UIButton *btnPrev;
//@property (strong, nonatomic) MarqueeLabel *songLabel;
@property (nonatomic, strong) NSArray *playlist;
//@property (strong, nonatomic) UILabel *artistLabel;
//@property (strong, nonatomic) UILabel *albumLabel;
@property (strong, nonatomic) UILabel *durationLabel;
@property (strong, nonatomic) UILabel *remainingLabel;
@property (strong, nonatomic) UIImageView *artworkImageView;

@property (strong, nonatomic) UIImage *playImage;
@property (strong, nonatomic) UIImage *pauseImage;
@property (strong, nonatomic) UIImage *nextImage;
@property (strong, nonatomic) UIImage *prevImage;

@property (nonatomic) BOOL isScrubbing;
@property (nonatomic) CGSize playerSize;
@property (nonatomic) float savedValue;
@property (nonatomic) BOOL isPlaying;

@property (nonatomic, copy) void (^nextBlock)(void);
@property (nonatomic, copy) void (^prevBlock)(void);

-(MPMusicPlayerController *)mpMusicPlayer;

-(void)registerNotifications;

-(void)removeNotifications;

-(void)handle_NowPlayingItemChanged:(NSNotification*)notification;

-(void)handle_PlaybackStateChanged:(NSNotification*)notification;

@end

#pragma mark - Implementation & Initializers
@implementation JVMusicPlayer

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        // initializer
        [self setupPlayer];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        // initializer
        [self setupPlayer];
    }
    
    return self;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    @throw [NSException exceptionWithName:NSGenericException reason:@"Use the `initWithFrame:(CGRect)frame: or init` method instead." userInfo:nil];
}

// customs initializers

#pragma clang diagnostic pop


-(void)dealloc {
    [self removeNotifications];
}

- (void)setupPlayer
{
    self.playerSize = self.frame.size;
    
    self.playImage = [UIImage imageNamed:@"play.png"];
    self.pauseImage = [UIImage imageNamed:@"pause.png"];
    self.nextImage = [UIImage imageNamed:@"next.png"];
    self.prevImage = [UIImage imageNamed:@"prev.png"];
    
    // Obtain the music player's state so it can be restored after updating the playback queue.
    if(self.mpMusicPlayer.playbackState == MPMoviePlaybackStatePlaying)
    {
        self.isPlaying = YES;
    }
    else
    {
        self.isPlaying = NO;
    }
    
    __block MPMusicPlayerController *blockPlayer = self.mpMusicPlayer;
    __weak JVMusicPlayer *weakSelf = self;
    self.nextBlock = ^{
        [blockPlayer setNowPlayingItem:[weakSelf nextItem]];
    };
    
    self.prevBlock = ^{
        [blockPlayer skipToPreviousItem];
    };
    
    //    __weak AudioPlayer *weakSelf = self;
    //    __block MPMusicPlayerController *bgPlayer = self.musicPlayer;
    //    __block MPMediaItemCollection *bgMediaCollection = self.userMediaItemCollection;
    
    //    self.block = ^(void){
    [self updateQueueWithCollection:self.userMediaItemCollection];
    [self.mpMusicPlayer setQueueWithItemCollection:self.userMediaItemCollection];
    //    };
    
//    [self addSubview:self.slider];
//    [self addSubview:self.songLabel];
    [self handleTrackTime];
//    [self addSubview:self.durationLabel];
//    [self addSubview:self.remainingLabel];
    [self addSubview:self.btnPlay];
    [self addSubview:self.btnNext];
    [self addSubview:self.btnPrev];
    [self addSubview:self.artworkImageView];
    
    [self registerNotifications];
}

#pragma mark - Media Player Delegate

- (void)playableContentManager:(MPPlayableContentManager *)contentManager initiatePlaybackOfContentItemAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(NSError *))completionHandler
{
    
}


#pragma mark - Media Player Data Source

- (MPContentItem *)contentItemAtIndexPath:(NSIndexPath *)indexPath
{
    MPContentItem *item = nil;
    
    return item;
}

- (NSInteger)numberOfChildItemsAtIndexPath:(NSIndexPath *)indexPath
{
    return 1;
}


#pragma mark - Queuing Songs

- (void)updateQueueWithCollection:(MPMediaItemCollection *)collection
{
    // Save the now-playing item and its current playback time.
    MPMediaItem *nowPlayingItem = self.mpMusicPlayer.nowPlayingItem;
    NSTimeInterval currentPlaybackTime = self.mpMusicPlayer.currentPlaybackTime;
    
    // Combine the previously-existing media item collection with the new one
    NSMutableArray *combinedMediaItems = [[self.userMediaItemCollection items] mutableCopy];
    NSArray *newMediaItems = [collection items];
    [combinedMediaItems addObjectsFromArray:newMediaItems];
    
    [self setUserMediaItemCollection:[MPMediaItemCollection collectionWithItems:(NSArray*)combinedMediaItems]];
    [self.mpMusicPlayer setQueueWithItemCollection:self.userMediaItemCollection];
    
    self.playlist = [self playlist];
    
    // Restore the now-playing item and its current playback time.
    self.mpMusicPlayer.nowPlayingItem = nowPlayingItem;
    self.mpMusicPlayer.currentPlaybackTime = currentPlaybackTime;
    
    [self.mpMusicPlayer prepareToPlay];
    
    if (self.isPlaying)
    {
        [self.mpMusicPlayer play];
    }
}

-(MPMediaItem *)nextItem
{
    int currentIndex = (int)[self.mpMusicPlayer indexOfNowPlayingItem];
    MPMediaItem *nextItem;
    
    if([self.playlist objectAtIndex:currentIndex+1] != nil)
    {
        nextItem = [self.playlist objectAtIndex:currentIndex+1];
    }
    else
    {
        nextItem = [self.playlist objectAtIndex:0];
    }
    
    //    [self.musicPlayer prepareToPlay];
    
    return nextItem;
}

-(MPMediaItem *)previousItem
{
    int currentIndex = (int)[self.mpMusicPlayer indexOfNowPlayingItem];
    MPMediaItem *previousItem;
    
    if([self.playlist objectAtIndex:currentIndex-1] != nil)
    {
        previousItem = [self.playlist objectAtIndex:currentIndex-1];
    }
    else
    {
        previousItem = [self.playlist lastObject];
    }
    
    //    [self.musicPlayer prepareToPlay];
    
    return previousItem;
}


#pragma mark - Setters & Getters

-(MPMusicPlayerController *)mpMusicPlayer
{
    if(!_mpMusicPlayer)
    {
        _mpMusicPlayer = [MPMusicPlayerController systemMusicPlayer];
    }
    
    return _mpMusicPlayer;
}

-(MPMediaItemCollection *)userMediaItemCollection
{
    if(!_userMediaItemCollection)
    {
        _userMediaItemCollection = [MPMediaItemCollection collectionWithItems:[MPMediaQuery songsQuery].items];
    }
    return _userMediaItemCollection;
}

-(NSArray *)playlist
{
    if(!_playlist)
    {
        _playlist = [MPMediaQuery songsQuery].items;
    }
    return _playlist;
}

-(UISlider *)slider
{
    if(!_slider)
    {
//        _slider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.durationLabel.frame), self.sliderY, self.sliderWidth, 40)];
//        _slider.backgroundColor = [UIColor clearColor];
//        _slider.continuous = YES;
//        _slider.maximumValue = 1.0f;
//        _slider.minimumValue = 0.0f;
//        
//        FAKFontAwesome *dotIcon = [FAKFontAwesome circleIconWithSize:20];
//        [dotIcon addAttribute:NSForegroundColorAttributeName value:FlatWhite];
//        UIImage *iconImage = [dotIcon imageWithSize:CGSizeMake(20, 20)];
//        
//        FAKFontAwesome *square = [FAKFontAwesome squareIconWithSize:3];
//        [square addAttribute:NSForegroundColorAttributeName value:FlatWhiteDark];
//        UIImage *squareImg = [square imageWithSize:CGSizeMake(3, _slider.frame.size.width)];
//        UIImage *stetchLeftTrack = [squareImg stretchableImageWithLeftCapWidth:1.0 topCapHeight:0.0];
//        
//        FAKFontAwesome *squareB = [FAKFontAwesome squareIconWithSize:3];
//        [squareB addAttribute:NSForegroundColorAttributeName value:FlatBlack];
//        UIImage *squareImgB = [squareB imageWithSize:CGSizeMake(3, _slider.frame.size.width)];
//        UIImage *stetchRightTrack = [squareImgB stretchableImageWithLeftCapWidth:1.0 topCapHeight:0.0];
//        
//        [_slider setThumbImage:iconImage forState:UIControlStateNormal];
//        [_slider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
//        [_slider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
//        
//        [_slider addTarget:self action:@selector(handleSliderMove:) forControlEvents:UIControlEventValueChanged];
    }
    
    return _slider;
}

//-(MarqueeLabel *)songLabel
//{
//    if(!_songLabel)
//    {
//        _songLabel = [[MarqueeLabel alloc] initWithFrame:CGRectMake(self.frame.size.width*0.03, self.songLblY, self.frame.size.width*0.94, 18)];
//        _songLabel.marqueeType = MLContinuous;
//        _songLabel.scrollDuration = 15.0;
//        _songLabel.animationCurve = UIViewAnimationOptionCurveEaseInOut;
//        _songLabel.fadeLength = 1.0f;
//        _songLabel.backgroundColor = [UIColor clearColor];
//        _songLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
//        _songLabel.textColor = [UIColor whiteColor];
//        _songLabel.textAlignment = NSTextAlignmentCenter;
//        
//        MPMediaItem *currentItem = self.musicPlayer.nowPlayingItem;
//        
//        if([[currentItem valueForProperty:MPMediaItemPropertyTitle] isEqualToString:@""])
//        {
//            _songLabel.text = @"Unknown";
//        }
//        else
//        {
//            _songLabel.text   = [currentItem valueForProperty:MPMediaItemPropertyTitle];
//        }
//    }
//    
//    return _songLabel;
//}

-(UILabel *)durationLabel
{
    if(!_durationLabel)
    {
//        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, self.durationY, 47, 13)];
//        _durationLabel.backgroundColor = [UIColor clearColor];
//        _durationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
//        _durationLabel.textColor = [UIColor whiteColor];
//        _durationLabel.textAlignment = NSTextAlignmentCenter;
//        _durationLabel.text = @"0:00";
    }
    
    return _durationLabel;
}

-(UILabel *)remainingLabel
{
    if(!_remainingLabel)
    {
//        _remainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-53, self.remainingY, 52, 13)];
//        _remainingLabel.backgroundColor = [UIColor clearColor];
//        _remainingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
//        _remainingLabel.textColor = [UIColor whiteColor];
//        _remainingLabel.textAlignment = NSTextAlignmentCenter;
//        _remainingLabel.text = @"0:00";
    }
    
    return _remainingLabel;
}

-(UIImageView *)artworkImageView
{
    if(!_artworkImageView)
    {
//        _artworkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2-self.artworkSize/2, 10, self.artworkSize, self.artworkSize)];
    }
    
    return _artworkImageView;
}

-(UIButton *)btnPlay
{
    if(!_btnPlay)
    {
        _btnPlay = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnPlay.frame = CGRectMake(self.frame.size.width/2-40, 10, 80, 80);
        [_btnPlay addTarget:self action:@selector(playControlEvent:) forControlEvents:UIControlEventTouchUpInside];
        _btnPlay.backgroundColor = [UIColor clearColor];
        
        if(_isPlaying)
        {
            [_btnPlay setBackgroundImage:self.pauseImage forState:UIControlStateNormal];
        }
        else
        {
            [_btnPlay setBackgroundImage:self.playImage forState:UIControlStateNormal];
        }
    }
    
    return _btnPlay;
}

-(UIButton *)btnNext
{
    if(!_btnNext)
    {
        _btnNext = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGFloat _x = CGRectGetMaxX(self.btnPlay.frame)+5;
        _btnNext.frame = CGRectMake(_x, CGRectGetMidY(self.btnPlay.frame)-30, 60, 60);
        [_btnNext addTarget:self action:@selector(nextControlEvent:) forControlEvents:UIControlEventTouchUpInside];
        _btnNext.backgroundColor = [UIColor clearColor];
        [_btnNext setBackgroundImage:self.nextImage forState:UIControlStateNormal];
    }
    
    return _btnNext;
}

-(UIButton *)btnPrev
{
    if(!_btnPrev)
    {
        _btnPrev = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGFloat _x = CGRectGetMinX(self.btnPlay.frame)-5-60;
        _btnPrev.frame = CGRectMake(_x, CGRectGetMinY(self.btnPlay.frame)-30, 60, 60);
        [_btnPrev addTarget:self action:@selector(prevControlEvent:) forControlEvents:UIControlEventTouchUpInside];
        _btnPrev.backgroundColor = [UIColor clearColor];
        [_btnPrev setBackgroundImage:self.prevImage forState:UIControlStateNormal];
    }
    
    return _btnPrev;
}


#pragma mark - Player Buttons

-(void)playControlEvent:(UIButton*)btn {
    
    if(self.isPlaying)
    {
        UIImage *playImage = [UIImage imageNamed:@"play.png"];
        [self.btnPlay setBackgroundImage:playImage forState:UIControlStateNormal];
        [self pause];
        
        self.isPlaying = NO;
    }
    else
    {
        UIImage *pauseImage = [UIImage imageNamed:@"pause.png"];
        [self.btnPlay setBackgroundImage:pauseImage forState:UIControlStateNormal];
        [self play];
        
        self.isPlaying = YES;
    }
}

-(void)nextControlEvent:(UIButton*)btn
{
    [self next];
}

-(void)prevControlEvent:(UIButton*)btn
{
    [self prev];
}


#pragma mark - UISlider Helper Functions

-(void)handleTrackTime
{
    if (!_currentTimer)
    {
        NSNumber *playBackTime = [NSNumber numberWithFloat:self.mpMusicPlayer.currentPlaybackTime];
        _currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                         target:self
                                                       selector:@selector(timeIntervalFinished:)
                                                       userInfo:@{@"playbackTime" : playBackTime}
                                                        repeats:YES];
    }
}

-(void) timeIntervalFinished:(NSTimer*)sender
{
    [self playbackTimeUpdated:self.mpMusicPlayer.currentPlaybackTime];
}

-(void) playbackTimeUpdated:(CGFloat)playbackTime
{
    [self updatePosition];
}

- (void)handleSliderMove:(UISlider*)sender
{
    CGFloat currentPlayback = sender.value * [[self.mpMusicPlayer.nowPlayingItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue];
    self.mpMusicPlayer.currentPlaybackTime = currentPlayback;
}

-(BOOL)beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    self.isScrubbing = NO;
    return YES;
}

- (void)endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    self.savedValue = _slider.value;
    self.isScrubbing = YES;
}

-(void)updatePosition {
    
    if (!_slider.tracking)
    {
        if (self.isScrubbing)
        {
            self.slider.value = self.savedValue;
            self.isScrubbing = NO;
            [self updateDurationLabel];
        }
        else
        {
            CGFloat percent = self.mpMusicPlayer.currentPlaybackTime / [[self.mpMusicPlayer.nowPlayingItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue];
            self.slider.value = percent;
            [self updateDurationLabel];
        }
    }
}


#pragma mark - Notifications

-(void)registerNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handle_NowPlayingItemChanged:)
                               name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                             object:self.mpMusicPlayer];
    
    [notificationCenter addObserver:self
                           selector:@selector(handle_PlaybackStateChanged:)
                               name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                             object:self.mpMusicPlayer];
    
    [self.mpMusicPlayer beginGeneratingPlaybackNotifications];
}

-(void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                                  object:self.mpMusicPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                                  object:self.mpMusicPlayer];
    
    [self.mpMusicPlayer endGeneratingPlaybackNotifications];
    
}

-(void)handle_NowPlayingItemChanged:(NSNotification*)notification
{
    MPMediaItem *currentItem = self.mpMusicPlayer.nowPlayingItem;
    
//    self.songLabel.text   = [currentItem valueForProperty:MPMediaItemPropertyTitle];
    //    self.artistLabel.text = [currentItem valueForProperty:MPMediaItemPropertyArtist];
    //    self.albumLabel.text  = [currentItem valueForProperty:MPMediaItemPropertyAlbumTitle];
    
    // The total duration of the track...
    long totalPlaybackTime = [[[self.mpMusicPlayer nowPlayingItem] valueForProperty: @"playbackDuration"] longValue];
    int tHours = (int)(totalPlaybackTime / 3600);
    int tMins = (int)((totalPlaybackTime/60) - tHours*60);
    int tSecs = (totalPlaybackTime % 60 );
    self.durationLabel.text = [NSString stringWithFormat:@"%i:%02d:%02d", tHours, tMins, tSecs ];
    
    CGSize artworkImageViewSize = CGSizeMake(80, 80);
    MPMediaItemArtwork *artwork = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
    
    if (artwork != nil)
    {
        self.artworkImageView.image = [artwork imageWithSize:artworkImageViewSize];
    }
    else
    {
        self.artworkImageView.image = [UIImage imageNamed:@"kingg.jpg"];
    }
    
    self.artworkImageView.layer.backgroundColor = [[UIColor clearColor] CGColor];
    self.artworkImageView.layer.cornerRadius = 62;
    self.artworkImageView.layer.borderWidth = 1.0;
    self.artworkImageView.layer.masksToBounds = YES;
    self.artworkImageView.layer.borderColor = [[[UIColor blackColor] colorWithAlphaComponent:0.8] CGColor];
    self.artworkImageView.alpha = 0.8;
    
    [self sendSubviewToBack:self.artworkImageView];
}

-(void)handle_PlaybackStateChanged:(NSNotification*)notification
{
    // do something...
}

#pragma mark - Helper Functions

- (void)updateDurationLabel
{
    double nowPlayingItemDuration = [[[self.mpMusicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration]doubleValue];
    double currentTime = (double) [self.mpMusicPlayer currentPlaybackTime];
    double remainingTime = nowPlayingItemDuration - currentTime;
    
    NSString *timeElapsed;
    NSString *timeRemaining;
    
    if (nowPlayingItemDuration >= 3600.0)
    {
        timeElapsed = [NSString stringWithFormat: @"%01d:%02d:%02d",
                       (int)currentTime/3600,
                       (int) (currentTime/60)%60,
                       (int) currentTime%60];
        timeRemaining = [NSString stringWithFormat:@"-%01d:%02d:%02d",
                         (int)remainingTime/3600,
                         (int) (remainingTime/60)%60,
                         (int) remainingTime%60];
        
    }
    else
    {
        timeElapsed = [NSString stringWithFormat: @"%02d:%02d",
                       (int) currentTime/60,
                       (int) currentTime%60];
        timeRemaining = [NSString stringWithFormat:@"-%02d:%02d",
                         (int) remainingTime/60,
                         (int) remainingTime%60];
    }
    
    if(currentTime < 3600.0)
    {
        timeElapsed = [NSString stringWithFormat: @"%02d:%02d",
                       (int) currentTime/60,
                       (int) currentTime%60];
    }
    
    if(remainingTime < 3600.0)
    {
        timeRemaining = [NSString stringWithFormat:@"-%02d:%02d",
                         (int) remainingTime/60,
                         (int) remainingTime%60];
    }
    
    self.durationLabel.text = timeElapsed;
    self.remainingLabel.text = timeRemaining;
    
}

-(void)play
{
    dispatch_async(kBgThreadDefault, ^{
        [self.mpMusicPlayer play];
    });
    self.isPlaying = YES;
}

-(void)pause
{
    dispatch_async(kBgThreadDefault, ^{
        [self.mpMusicPlayer pause];
    });
    self.isPlaying = NO;
}

-(void)stop
{
    dispatch_async(kBgThreadDefault, ^{
        [self.mpMusicPlayer stop];
    });
    self.isPlaying = NO;
}

-(void)next//:(void(^)(void))block
{
    //    __block MPMusicPlayerController *blockPlayer = self.musicPlayer;
    //    __weak AudioPlayer *weakSelf = self;
    //    dispatch_async(kBgThreadLow, ^{
    //        [blockPlayer setNowPlayingItem:[weakSelf nextItem]];
    self.nextBlock();
    //    });
}

-(void)prev
{
    dispatch_async(kBgThreadDefault, ^(void){
        //    __block MPMusicPlayerController *blockPlayer = self.musicPlayer;
        //    self.block = ^{
        [self.mpMusicPlayer skipToPreviousItem];
        //    };
    });
}

@end