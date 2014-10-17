//
//  DetailViewController.m
//  TweetTest
//
//  Created by Eugene Dimitrow on 10/13/14.
//  Copyright (c) 2014 Eugene Dimitrow. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userFriendsLabel;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageWithData:self.imageData];
    self.userPicture.image = image;
    self.userNameLabel.text = self.name;
    self.userFriendsLabel.text = [NSString stringWithFormat:@"#of friends: %@", self.friends];
    NSLog(@"data: %@", self.imageData);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
