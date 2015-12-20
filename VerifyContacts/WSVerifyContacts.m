 //
//  WSVerifyContacts.m
//  Boku
//
//  Created by Ghanshyam on 8/11/15.
//  Copyright (c) 2015 Plural Voice. All rights reserved.
//

#import "WSVerifyContacts.h"
#import "Person.h"
#import "DBContacts.h"


@implementation WSVerifyContacts


/**
 *  WSInviteContact Initialization with shared contacts
 *
 *  @param arrContacts : container of contacts
 *
 *  @return : object
 */
-(id)initWithContacts:(NSMutableArray *)arrContacts{
    self = [super init];
    if (self) {
        
        self.arrMutableContacts = arrContacts;
    }
    return self;
}


/**
 *  Here we are overriding callService method
 */
-(void)callServiceWithSuccessBlock:(void(^)(id response, Class modelClass , id delegate))successHandler withFailureBlock:(void(^)(id response, Class modelClass , id delegate))failureHandler{
    
    
    //Getting those contacts where SYNCED = 'NO'
    NSArray *arrRecentContacts = [APPDELEGATE.databaseHandler executeQuery:@"SELECT * FROM CONTACTS WHERE SYNCED = 'NO' AND IS_UNKNOWN_USER = 'NO'"];
    
    //Showing Loader
    [APPDELEGATE.loader show];
    NSLog(@"loader show in WSVerify Contacts");
    
    NSMutableDictionary *dictHeaders = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[CommonFunctions getUserDefaultValue:@"token"],@"token", nil];
    
    
    
    
    //NSString *contacts;
    NSMutableArray *arrWebContacts = [[NSMutableArray alloc] init];
    
    for (int counter = 0;counter<arrRecentContacts.count;counter++) {
        DBContacts *contact = [arrRecentContacts objectAtIndex:counter];
        
        NSMutableDictionary *dictContact = [[NSMutableDictionary alloc] init];
        [dictContact setObject:contact.OLD_NAME forKey:@"old_name"];
        [dictContact setObject:contact.NAME forKey:@"name"];
        [dictContact setObject:contact.PHONE forKey:@"phone_number"];
        
        [arrWebContacts addObject:dictContact];
        
    }
    
    
    NSString *deletingContacts;
//    for (int counter = 0;counter<arrDeletingContacts.count;counter++) {
//        DBContacts *contact = [arrDeletingContacts objectAtIndex:counter];
//        
//        if (counter==0) {
//            deletingContacts = [NSString stringWithFormat:@"%@",[CommonFunctions removeSpecialCharectorsOtherThenNumericFromString:contact.PHONE]];
//        }else{
//            deletingContacts = [contacts stringByAppendingString:[NSString stringWithFormat:@",%@",[CommonFunctions removeSpecialCharectorsOtherThenNumericFromString:contact.PHONE]]];
//        }
//    }
    
    NSString *timeStamp = [CommonFunctions getUserDefaultValue:@"timestamp"];
    
    NSMutableDictionary *dictParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:(arrWebContacts?arrWebContacts:@""),@"contact_nos",(deletingContacts?deletingContacts:@""),@"delete_contact_nos",(timeStamp?timeStamp:@""),@"timestamp", nil];
    
//    NSData *data = [NSJSONSerialization dataWithJSONObject:dictParams options:NSJSONWritingPrettyPrinted error:nil];
//    
//    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    
    NSLog(@"verify contacts params is %@ , %@",dictParams,dictHeaders);
    
    
    [self startRequestWithHttpMethod:kHttpMethodTypePost withHttpHeaders:dictHeaders withServiceName:@"/verifyBokuContacts" withParameters:dictParams withSuccess:^(NSURLSessionDataTask *task, id responseObject) {
        
        
        //see description in Contacts interface file
        [Contacts sharedInstance].isContactsContainerVerified = YES;
        
        
        NSLog(@"verify contacts success == %@",responseObject);
        NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
        
        NSMutableDictionary *dictResponse = (NSMutableDictionary *)responseObject;
        [dictResponse setObject:[NSNumber numberWithInteger:res.statusCode] forKey:@"status_code"];
        
        if (res.statusCode == 200) {
            NSArray *arrServerContacts = [[dictResponse objectForKey:@"data"] objectForKey:@"app_users"];
            
            if ([[dictResponse objectForKey:@"data"] objectForKey:@"timestamp"] &&
                ((NSString *)[[dictResponse objectForKey:@"data"] objectForKey:@"timestamp"]).length>0) {
                [CommonFunctions setUserDefault:@"timestamp" value:[[dictResponse objectForKey:@"data"] objectForKey:@"timestamp"]];
            }
            
            if(arrServerContacts){
                [[Contacts sharedInstance] syncLocalContactsWithServerContacts:arrServerContacts];
            }
        }
        
        if (successHandler) {
            successHandler(responseObject,[self class],(_delegate?_delegate:nil));
        }
        
        //Hide Loader
        [APPDELEGATE.loader hide];
        NSLog(@"loader hide verify contacts ws success");
        
        
    }withFailure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"verify contacts failure == %@",error);
        
        if (failureHandler) {
            failureHandler(error,[self class],(_delegate?_delegate:nil));
        }
        
        //Hide Loader
        [APPDELEGATE.loader hide];
        NSLog(@"loader hide verify contacts ws failure");
    }];
}

-(void)dealloc{
    NSLog(@"WSVerifyContacts dealloc ");
}


@end
