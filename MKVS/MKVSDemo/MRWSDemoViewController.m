//
//  MRWSDemoViewController.m
//  MKVS
//
//  Created by 王嘉宁 on 2019/7/4.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import "MRWSDemoViewController.h"
#import "MRWStorageManager.h"
#import "NormalFileManager.h"

@interface MRWSDemoViewController ()
@property (weak, nonatomic) IBOutlet UITextField *logContentTextField;

@property (nonatomic, strong, readwrite) MRWStorageManager *manager;

@end

@implementation MRWSDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.manager printFilePath];
}

- (IBAction)writeLogAction:(id)sender {
    NSDate *date = [NSDate date];
    NSString *log = self.logContentTextField.text;
    if (!self.logContentTextField.text || [self.logContentTextField.text isEqualToString:@""]) {
        log = @"{sgbiudsbfoanoidqobefowiawndonqeaobdqoiwdbwoefbd}\n";
    }
    [self.manager setLogContent:[NSString stringWithFormat:@"\"%@\":\"%@\"\n", date.description, log]];
}

- (IBAction)unmapAction:(id)sender {
    [self.manager unmapAndCloseFile];
}

- (IBAction)benchmarkAction:(id)sender {
    
    NSInteger writeTimes = 100000;
    
    long startTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    long endTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    NSInteger time = 0;
    startTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    while (time < writeTimes) {
        [self.manager setLogContent:[NSString stringWithFormat:@"%@%ld", @"log", time]];
        time++;
    }
    endTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    NSLog(@"manager : %ld", endTime - startTime);
    time = 0;
    NormalFileManager *nfmanager = [[NormalFileManager alloc] init];
    startTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    while (time < writeTimes) {
        [[NSString stringWithFormat:@"%@%ld", @"log", time] writeToFile:[nfmanager fileFullPath] atomically:NO encoding:NSUTF8StringEncoding error:nil];
        time++;
    }
    endTime = [[NSDate date] timeIntervalSince1970] * 10000000;
    NSLog(@"nfmanager : %ld", endTime - startTime);
}

- (IBAction)multiFileWriteButton:(id)sender {
    
    MRWStorageManager *multiFileManager = [[MRWStorageManager alloc] initWithFilePath:MRWSDefaultFilePath fileName:@"Dict" maxFileSize:20000];
    __weak MRWStorageManager *__weak_multiFileManager = multiFileManager;
    multiFileManager.reachMaxFileSizeHandler = ^(NSInteger fileCount, NSString * _Nonnull filePath, NSString * _Nonnull fileName) {
        MRWStorageManager *multiFileManager = __weak_multiFileManager;
        [multiFileManager setWorkPath:MRWSDefaultFilePath fileName:[NSString stringWithFormat:@"Dict%ld", fileCount]];
    };
    
    for (int i = 0; 1; i++) {
        if (![multiFileManager setLogContent:[NSString stringWithFormat:@"log %d\n", i]]) {
            break;
        }
    }
}


- (MRWStorageManager *)manager
{
    if (_manager == nil) {
        _manager = [[MRWStorageManager alloc] init];
    }
    return _manager;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
