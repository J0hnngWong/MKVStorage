//
//  MKVSDemoViewController.m
//  MKVS
//
//  Created by 王嘉宁 on 2019/6/27.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import "MKVSDemoViewController.h"
#import "MKVStorageManager.h"
#import "NormalFileManager.h"
#import "NFMDemoViewController.h"
#import "MKVPStorageManager.h"

@interface MKVSDemoViewController ()

@property (nonatomic, strong) MKVStorageManager *storageManager;
@property (nonatomic, strong) MKVPStorageManager *pageStorageManager;

@property (nonatomic, strong) NormalFileManager *normalManager;

@property (nonatomic, assign) int times;
@property (nonatomic, assign) long startTime;
@property (nonatomic, assign) long endTime;

@end

@implementation MKVSDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.storageManager printFilePath];
    [self.pageStorageManager printFilePath];
    self.times = 0;
    NSString *longestStringCanSaveOneTime = @"{\"string1\":\"string1\",\"string2\":\"string2\",\"string3\":\"string3\",\"string4\":\"string4\",\"string5\":\"string5\",\"string6\":\"string6\",\"string7\":\"string7\",\"string8\":\"string8\",\"string9\":\"string9\",\"string10\":\"string10\",\"string11\":\"string11\",\"string12\":\"string12\",\"string13\":\"string13\",\"string14\":\"string14\",\"string15\":\"string15\",\"string16\":\"string16\",\"string17\":\"string17\",\"string18\":\"string18\",\"string19\":\"string19\",\"string20\":\"string20\",\"string21\":\"string21\",\"string22\":\"string22\",\"string23\":\"string23\",\"string24\":\"string24\",\"string25\":\"string25\",\"string26\":\"string26\",\"string27\":\"string27\",\"string28\":\"string28\",\"string29\":\"string29\",\"string30\":\"string30\",\"string31\":\"string31\",\"string32\":\"string32\",\"string33\":\"string33\",\"string34\":\"string34\",\"string35\":\"string35\",\"string36\":\"string36\",\"string37\":\"string37\",\"string38\":\"string38\",\"string39\":\"string39\",\"string40\":\"string40\",\"string41\":\"string41\",\"string42\":\"string42\",\"string43\":\"string43\",\"string44\":\"string44\",\"string45\":\"string45\",\"string46\":\"string46\",\"string47\":\"string47\",\"string48\":\"string48\",\"string49\":\"string49\",\"string50\":\"string50\",\"string51\":\"string51\",\"string52\":\"string52\",\"string53\":\"string53\",\"string54\":\"string54\",\"string55\":\"string55\",\"string56\":\"string56\",\"string57\":\"string57\",\"string58\":\"string58\",\"string59\":\"string59\",\"string60\":\"string60\",\"string61\":\"string61\",\"string62\":\"string62\",\"string63\":\"string63\",\"string64\":\"string64\",\"string65\":\"string65\",\"string66\":\"string66\",\"string67\":\"string67\",\"string68\":\"string68\",\"string69\":\"string69\",\"string70\":\"string70\",\"string71\":\"string71\",\"string72\":\"string72\",\"string73\":\"string73\",\"string74\":\"string74\",\"string75\":\"string75\",\"string76\":\"string76\",\"string77\":\"string77\",\"string78\":\"string78\",\"string79\":\"string79\",\"string80\":\"string80\",\"string81\":\"string81\",\"string82\":\"string82\",\"string83\":\"string83\",\"string84\":\"string84\",\"string85\":\"string85\",\"string86\":\"string86\",\"string87\":\"string87\",\"string88\":\"string88\",\"string89\":\"string89\",\"string90\":\"string90\",\"string91\":\"string91\",\"string92\":\"string92\",\"string93\":\"string93\",\"string94\":\"string94\",\"string95\":\"string95\",\"string96\":\"string96\",\"string97\":\"string97\",\"string98\":\"string98\",\"string99\":\"string99\",\"string100\":\"string100\",\"string101\":\"string101\",\"string102\":\"string102\",\"string103\":\"string103\",\"string104\":\"string104\",\"string105\":\"string105\",\"string106\":\"string106\",\"string107\":\"string107\",\"string108\":\"string108\",\"string109\":\"string109\",\"string110\":\"string110\",\"string111\":\"string111\",\"string112\":\"string112\",\"string113\":\"string113\",\"string114\":\"string114\",\"string115\":\"string115\",\"string116\":\"string116\",\"string117\":\"string117\",\"string118\":\"string118\",\"string119\":\"string119\",\"string120\":\"string120\",\"string121\":\"string121\",\"string122\":\"string122\",\"string123\":\"string123\",\"string124\":\"string124\",\"string125\":\"string125\",\"string126\":\"string126\",\"string127\":\"string127\",\"string128\":\"string128\",\"string129\":\"string129\",\"string130\":\"string130\",\"string131\":\"string131\",\"string132\":\"string132\",\"string133\":\"string133\",\"string134\":\"string134\",\"string135\":\"string135\",\"string136\":\"string136\",\"string137\":\"string137\",\"string138\":\"string138\",\"string139\":\"string139\",\"string140\":\"string140\",\"string141\":\"string141\",\"string142\":\"string142\",\"string143\":\"string143\",\"string144\":\"string144\",\"string145\":\"string145\",\"string146\":\"string146\",\"string147\":\"string147\",\"string148\":\"string148\",\"string149\":\"string149\",\"string150\":\"string150\",\"string151\":\"string151\",\"string152\":\"string152\",\"string153\":\"string153\",\"string154\":\"string154\",\"string155\":\"string155\",\"string156\":\"string156\",\"string157\":\"string157\",\"string158\":\"string158\",\"string159\":\"string159\",\"string160\":\"string160\",\"string161\":\"string161\",\"string162\":\"string162\",\"string163\":\"string163\",\"string164\":\"string164\",\"string165\":\"string165\",\"string166\":\"string166\",\"string167\":\"string167\",\"string168\":\"string168\",\"string169\":\"string169\",\"string170\":\"string170\",\"string171\":\"string171\",\"string172\":\"string172\",\"string173\":\"string173\",\"string174\":\"string174\",\"string175\":\"string175\",\"string176\":\"string176\",\"string177\":\"string177\",\"string178\":\"string178\",\"string179\":\"string179\",\"string180\":\"st";
    NSLog(@"%lu", longestStringCanSaveOneTime.length);
//    NSData *data = [NSJSONSerialization dataWithJSONObject:longestStringCanSaveOneTime options:NSJSONWritingSortedKeys error:nil];
//    NSLog(@"%lu", data.length);
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)saveBool:(id)sender {
    [self.storageManager setBoolValue:YES forKey:@"bool"];
}
- (IBAction)saveInt:(id)sender {
    [self.storageManager setIntValue:5373468327 forKey:@"int"];
}
- (IBAction)saveString:(id)sender {
    [self.storageManager setStringValue:@"string" forKey:@"string"];
    [self.pageStorageManager setStringValue:@"string" forKey:@"string"];
}
- (IBAction)saveFloat:(id)sender {
    [self.storageManager setFloatValue:989.8605 forKey:@"float"];
}
- (IBAction)saveDate:(id)sender {
    [self.storageManager setDateValue:[NSDate date] forKey:@"date"];
}

- (IBAction)removeBool:(id)sender {
    [self.storageManager removeObjectForKey:@"bool"];
}
- (IBAction)removeInt:(id)sender {
    [self.storageManager removeObjectForKey:@"int"];
}
- (IBAction)removeString:(id)sender {
    [self.storageManager removeObjectForKey:@"string"];
}
- (IBAction)removeFloat:(id)sender {
    [self.storageManager removeObjectForKey:@"float"];
}
- (IBAction)removeDate:(id)sender {
    [self.storageManager removeObjectForKey:@"date"];
}

- (IBAction)getBool:(id)sender {
    BOOL boolValue = [self.storageManager getBoolValueForKey:@"bool"];
    NSLog(@"%d", boolValue);
}
- (IBAction)getInt:(id)sender {
    long intValue = [self.storageManager getIntValueForKey:@"int"];
    NSLog(@"%ld", intValue);
}
- (IBAction)getString:(id)sender {
    NSString *string = [self.storageManager getStringValueForKey:@"string"];
    NSLog(@"%@", string);
}
- (IBAction)getFloat:(id)sender {
    float floatValue = [self.storageManager getFloatValueForKey:@"float"];
    NSLog(@"%f", floatValue);
}
- (IBAction)getDate:(id)sender {
    NSDate *date = [self.storageManager getDateValueForKey:@"date"];
    NSLog(@"%@", date.description);
}

- (IBAction)recursionSaveData:(id)sender {
    NSMutableString *stringValue = [NSMutableString stringWithString:@"string1"];
    NSMutableString *stringKey = [NSMutableString stringWithString:@"string1"];
    for (int i = 170*self.times; i < 170*(self.times+1); i++) {
        stringValue = [NSMutableString stringWithFormat:@"%@%d", @"string", i];
        stringKey = stringValue;
        if (![self.storageManager setStringValue:stringValue forKey:stringKey]) {
            printf("write fail");
            break;
        }
    }
    self.times++;
    
    for (int i = 0; i < 600; i++) {
        stringValue = [NSMutableString stringWithFormat:@"%@%d", @"string", i];
        stringKey = stringValue;
        if (![self.pageStorageManager setStringValue:stringValue forKey:stringKey]) {
            printf("write fail");
            break;
        }
    }
}
- (IBAction)changeFile:(id)sender {
    [self.storageManager setWorkFileName:[NSString stringWithFormat:@"file%d", self.times]];
}

- (IBAction)removeChangedFile:(id)sender {
    [self.storageManager removeFileInDefaultPathWithFileName:@"file1"];
}
- (IBAction)removeDefaultFile:(id)sender {
    [self.storageManager removeFileInDefaultPathWithFileName:MKVSDefaultFileName];
}
- (IBAction)munmapFile:(id)sender {
    [self.storageManager unmapAndCloseFile];
}
- (IBAction)benchMarkButton:(id)sender {
    {
        NSMutableString *stringValue = [NSMutableString stringWithString:@"string1"];
        NSMutableString *stringKey = [NSMutableString stringWithString:@"string1"];
        self.startTime = [[NSDate date] timeIntervalSince1970] * 10000000;
        for (int i = 170*self.times; i < 170*(self.times+1); i++) {
            stringValue = [NSMutableString stringWithFormat:@"%@%d", @"string", i];
            stringKey = stringValue;
            if (![self.storageManager setStringValue:stringValue forKey:stringKey]) {
                printf("write fail");
                break;
            }
        }
        self.endTime = [[NSDate date] timeIntervalSince1970] * 10000000;
        NSLog(@"MKVS spend %ld seconds to write 170 string to file", self.endTime - self.startTime);
        self.times++;
    }
    self.times = 0;
    {
        NSMutableString *stringValue2 = [NSMutableString stringWithString:@"string1"];
        NSMutableString *stringKey2 = [NSMutableString stringWithString:@"string1"];
        self.startTime = [[NSDate date] timeIntervalSince1970] * 10000000;
        for (int i = 170*self.times; i < 170*(self.times+1); i++) {
            stringValue2 = [NSMutableString stringWithFormat:@"%@%d", @"string", i];
            stringKey2 = stringValue2;
            if (![self.normalManager setStringValue:stringValue2 forKey:stringValue2]) {
                printf("write fail");
                break;
            }
        }
        self.endTime = [[NSDate date] timeIntervalSince1970] * 10000000;
        NSLog(@"NFM spend %ld seconds to write 170 string to file", self.endTime - self.startTime);
        self.times++;
    }
}

- (MKVStorageManager *)storageManager
{
    if (_storageManager == nil) {
        _storageManager = [[MKVStorageManager alloc] init];
    }
    return _storageManager;
}

- (MKVPStorageManager *)pageStorageManager
{
    if (_pageStorageManager == nil) {
        _pageStorageManager = [[MKVPStorageManager alloc] init];
    }
    return _pageStorageManager;
}

- (NormalFileManager *)normalManager
{
    if (_normalManager == nil) {
        _normalManager = [[NormalFileManager alloc] init];
    }
    return _normalManager;
}

@end
