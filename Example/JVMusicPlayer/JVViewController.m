//
//  JVViewController.m
//  JVMusicPlayer
//
//  Created by Jorge Valbuena on 03/04/2015.
//  Copyright (c) 2014 Jorge Valbuena. All rights reserved.
//

#import "JVViewController.h"
#import <JVMusicPlayer/JVMusicPlayer.h>

@interface JVViewController ()

@property (strong, nonatomic) JVMusicPlayer *musicPlayer;

@end

@implementation JVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.musicPlayer = [[JVMusicPlayer alloc] initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 250)];
    [self.view addSubview:self.musicPlayer];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
