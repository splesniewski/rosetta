//  sar2json.m
//
#import <Foundation/Foundation.h>
#import <Foundation/NSRegularExpression.h>
#import <Foundation/NSTextCheckingResult.h>
#import <Foundation/NSJSONSerialization.h>

//################################################################
int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSMutableDictionary *dJSONData = [[NSMutableDictionary alloc]init];
        NSMutableDictionary *dJSONMeta = [[NSMutableDictionary alloc]init];
        [dJSONData setValue:[[NSMutableDictionary alloc]init] forKey:@"data"];
        NSMutableArray *dJSONMetaCols = [[NSMutableArray alloc] init];

        char *line = NULL;
        size_t len = 0;
        ssize_t read;
        
        // setup regexp that we'll be looking for
        NSRegularExpression *rMasterHeader = [NSRegularExpression regularExpressionWithPattern:@"^(Linux) (\\S+) \\((\\S+)\\)[ \\s]+(\\d+)/(\\d+)/(\\d+)"
                                                                                       options:NSRegularExpressionAnchorsMatchLines
                                                                                         error:NULL];
        
        NSRegularExpression *rHeader = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+):(\\d+):(\\d+) (\\S\\S)\\s+(IFACE)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)"
                                                                                 options:NSRegularExpressionAnchorsMatchLines
                                                                                   error:NULL];
        
        NSRegularExpression *rData = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+):(\\d+):(\\d+) (\\S\\S)\\s+(\\S+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)\\s+(\\d+\\.\\d+)"
                                                                               options:NSRegularExpressionAnchorsMatchLines
                                                                                 error:NULL];
        
        NSRegularExpression *rFooter = [NSRegularExpression regularExpressionWithPattern:@"^Average:"
                                                                                 options:NSRegularExpressionAnchorsMatchLines
                                                                                   error:NULL];
        
        NSRegularExpression *rBlankLine = [NSRegularExpression regularExpressionWithPattern:@"^$"
                                                                                    options:NSRegularExpressionAnchorsMatchLines
                                                                                      error:NULL];
        
        while ((read = getline(&line, &len, stdin)) != -1) {
            if (line[strlen(line) - 1] == '\n') { line[strlen(line) - 1] = '\0'; } //remove newline
            
            @autoreleasepool {
                NSString *inputLine = [[NSString alloc] initWithUTF8String:line];
                NSRange inputLineRange=NSMakeRange(0, [inputLine length]);
                
                // check out each regexp
                if ([rMasterHeader numberOfMatchesInString:inputLine options:0 range:inputLineRange]){
                    @autoreleasepool {
                        NSTextCheckingResult *firstMatch=[rMasterHeader firstMatchInString:inputLine options:0 range:inputLineRange];
                        
                        [dJSONData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 1]] forKey:@"operatingsystem"];
                        [dJSONData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 2]] forKey:@"operatingsystemversion"];
                        [dJSONData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 3]] forKey:@"hostname"];
                        
                        [dJSONMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 4]] forKey:@"month"];
                        [dJSONMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 5]] forKey:@"dom"];
                        [dJSONMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 6]] forKey:@"year"];
                    }
                    
                }else if ([rHeader numberOfMatchesInString:inputLine options:0 range:inputLineRange]){
                    @autoreleasepool {
                        NSUInteger r;
                        NSTextCheckingResult *firstMatch=[rHeader firstMatchInString:inputLine options:0 range:inputLineRange];
                        
                        // copy all columns header for later use
                        // (index 0 contains the entire match)
                        for (r=1; r < [firstMatch numberOfRanges]; r++){
                            [dJSONMetaCols addObject: [inputLine substringWithRange:[firstMatch rangeAtIndex:r]]];
                        }
                    }
                    
                }else if ([rData numberOfMatchesInString:inputLine options:0 range:inputLineRange]){
                    @autoreleasepool {
                        NSTextCheckingResult *firstMatch=[rData firstMatchInString:inputLine options:0 range:inputLineRange];
                        
                        NSMutableDictionary *recordData=[[NSMutableDictionary alloc] init];
                        NSMutableDictionary *recordMeta=[[NSMutableDictionary alloc] init];
                        
                        [recordMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 1]] forKey:@"hour"];
                        [recordMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 2]] forKey:@"minute"];
                        [recordMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 3]] forKey:@"second"];
                        [recordMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 4]] forKey:@"meridiem"];
                        [recordMeta setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 5]] forKey:@"IFACE"];
                        
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 6]] forKey:[dJSONMetaCols objectAtIndex:5]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 7]] forKey:[dJSONMetaCols objectAtIndex:6]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 8]] forKey:[dJSONMetaCols objectAtIndex:7]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 9]] forKey:[dJSONMetaCols objectAtIndex:8]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 10]] forKey:[dJSONMetaCols objectAtIndex:9]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 11]] forKey:[dJSONMetaCols objectAtIndex:10]];
                        [recordData setValue:[inputLine substringWithRange:[firstMatch rangeAtIndex: 12]] forKey:[dJSONMetaCols objectAtIndex:11]];
                        
                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                        [df setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
                        NSDate *myDate = [df dateFromString:[NSString stringWithFormat:@"%4@-%2@-%2@ %2@:%2@:%2@ %@",
                                                             [dJSONMeta objectForKey: @"year"],
                                                             [dJSONMeta objectForKey: @"month"],
                                                             [dJSONMeta objectForKey: @"dom"],
                                                             [recordMeta objectForKey:@"hour"],
                                                             [recordMeta objectForKey:@"minute"],
                                                             [recordMeta objectForKey:@"second"],
                                                             [recordMeta objectForKey:@"meridiem"]
                                                             ]
                                          ];

                        NSString *timeStr=[NSString stringWithFormat:@"%u",(int)[myDate timeIntervalSince1970]];
                        
                        // allocate a new structure to hold interface info for this time period
                        if ( [[dJSONData objectForKey: @"data"] objectForKey:timeStr] == nil){
                            NSMutableDictionary *temp=[[NSMutableDictionary alloc]init];
                            [[dJSONData objectForKey: @"data"] setValue:temp forKey: timeStr];
                        }
                        
                        // insert interface information
                        [[[dJSONData objectForKey: @"data"] objectForKey: timeStr]
                         setValue:recordData
                         forKey:[NSString stringWithFormat:@"%@",[recordMeta objectForKey:@"IFACE"]]];
                    }
                    
                }else if ([rFooter numberOfMatchesInString:inputLine options:0 range:inputLineRange]){
                    // ignore the 'Average' lines at the end.
                    
                }else if ([rBlankLine numberOfMatchesInString:inputLine options:0 range:inputLineRange]){
                    // ignore Blank Lines
                    
                }else{
                    NSLog(@"NOT PARSED:%@", inputLine);
                }
            }
        }
        free(line); // free getline storage

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dJSONData
                                                           options:NSJSONWritingPrettyPrinted error:NULL];
        NSString *output = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
	fprintf(stdout, "%s\n", [[NSString stringWithFormat:@"%@", output] UTF8String]);
    }
    
    return 0;
}
