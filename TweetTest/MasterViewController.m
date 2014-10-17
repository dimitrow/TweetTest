//
//  MasterViewController.m
//  TweetTest
//
//  Created by Eugene Dimitrow on 10/13/14.
//  Copyright (c) 2014 Eugene Dimitrow. All rights reserved.
//

#define kAccessToken  @"AAAAAAAAAAAAAAAAAAAAADiJRQAAAAAAt%2Brjl%2Bqmz0rcy%2BBbuXBBsrUHGEg%3Dq0EK2aWqQMb15gCZNwZo9yqae0hpe2FDsS92WAu0g"
#define kQuery 3
#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController ()
{
    NSInteger index;
}


@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (strong, nonatomic) NSMutableDictionary *fetchedTweets;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLResponse *response;
@property (strong) NSMutableArray *records;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchTextField.delegate = self;
    self.progressBar.hidden = YES;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)getTwits:(id)sender
{
    [self performSelector:@selector(fetchTwits)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self performSelector:@selector(fetchTwits)];
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    index = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"tweetDetail" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tweetDetail"]) {
        
        DetailViewController *destViewController = segue.destinationViewController;;
        

        destViewController.name = [[self.records objectAtIndex:index] valueForKey:@"userName"];
        destViewController.imageData = [NSData dataWithData:[[self.records objectAtIndex:index] valueForKey:@"userImage"]];
        destViewController.friends = [[self.records objectAtIndex:index] valueForKey:@"friends"];
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [context deleteObject:[self.records objectAtIndex:indexPath.row]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Delete! %@ %@", error, [error localizedDescription]);
            return;
        }
        
        [self.records removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark connection delegate methods

- (void)fetchTwits
{
    self.progressBar.hidden = YES;

    self.fetchedTweets = nil;
    NSString *searchString = [self.searchTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?q=%%23%@&result_type=recent&count=%d", searchString, kQuery];

    NSString *appToken = [NSString stringWithFormat:@"Bearer %@", kAccessToken];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60];
    [request setValue:appToken forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"CONNECTION ERROR");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    responseData = [[NSMutableData alloc] init];
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
    
    NSNumber *resourceLength = [NSNumber numberWithUnsignedInteger:[responseData length]];
    float current = [resourceLength floatValue];
    float expected = [[NSNumber numberWithUnsignedInteger:[self.response expectedContentLength]] floatValue];
    float progress = current / expected;
    
    self.progressBar.hidden = NO;
    
    self.progressBar.progress = progress;
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.progressBar.hidden = NO;
    self.progressBar.progress = 1.0;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        self.fetchedTweets = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
        
        for (int i =0; i < kQuery; i++) {
            
            NSString *user = [[[[self.fetchedTweets valueForKey:@"statuses"] objectAtIndex:i] valueForKey:@"user"] valueForKey:@"name"];
            NSString *text = [[[self.fetchedTweets valueForKey:@"statuses"] objectAtIndex:i] valueForKey:@"text"];
            NSString *dateCreated = [[[self.fetchedTweets valueForKey:@"statuses"] objectAtIndex:i] valueForKey:@"created_at"];
            
            NSInteger friends = [[[[[self.fetchedTweets valueForKey:@"statuses"] objectAtIndex:i] valueForKey:@"user"] valueForKey:@"friends_count"] intValue];
            NSNumber *friendsNumber = [NSNumber numberWithInteger:friends];
            NSURL *imageURL = [NSURL URLWithString:[[[[self.fetchedTweets valueForKey:@"statuses"] objectAtIndex:i] valueForKey:@"user"] valueForKey:@"profile_image_url"]];
            
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            
            NSManagedObject *twitRecord = [NSEntityDescription insertNewObjectForEntityForName:@"Twit" inManagedObjectContext:context];
            
            [twitRecord setValue:text forKey:@"text"];
            [twitRecord setValue:user forKey:@"userName"];
            [twitRecord setValue:imageData forKey:@"userImage"];
            [twitRecord setValue:dateCreated forKey:@"created"];
            [twitRecord setValue:friendsNumber  forKey:@"friends"];
            
        }
        
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            

            [self.tableView reloadData];
            
        });
        
    });
    
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Twit"];
    self.records = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    return [self.records count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    UILabel *userName = (UILabel *)[cell viewWithTag:23];
    UILabel *twit = (UILabel *)[cell viewWithTag:22];
    UILabel *dateLabel = (UILabel *) [cell viewWithTag:20];

    UIImageView *user = (UIImageView *)[cell viewWithTag:21];
    user.layer.cornerRadius = user.frame.size.width/2;
    user.layer.masksToBounds = YES;

    userName.text = [[self.records objectAtIndex:indexPath.row] valueForKey:@"userName"];
    twit.text = [[self.records objectAtIndex:indexPath.row] valueForKey:@"text"];
    
    dateLabel.text = [[self.records objectAtIndex:indexPath.row] valueForKey:@"created"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        UIImage *image = [UIImage imageWithData:[[self.records objectAtIndex:indexPath.row] valueForKey:@"userImage"]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{

            user.image = image;
            
        });
        
    });
    
    return cell;
}

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

@end
