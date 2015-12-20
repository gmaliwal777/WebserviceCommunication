//
//  WSVerifyContacts.h
//  Boku
//
//  Created by Ghanshyam on 8/11/15.
//  Copyright (c) 2015 Plural Voice. All rights reserved.
//

#import "HTTPService.h"

@interface WSVerifyContacts : HTTPService


/**
 *  weak reference to shared mutalbe contacts. don't make it nil in dealloc ,since its refereing to shared contacts container
 */
@property (nonatomic,weak)  NSMutableArray *arrMutableContacts;


/**
 *  Reference to calling context
 */
@property (nonatomic,weak)  id      delegate;


/**
 *  Here we are overriding callService method
 */
-(void)callServiceWithSuccessBlock:(void(^)(id response, Class modelClass , id delegate))successHandler withFailureBlock:(void(^)(id response, Class modelClass , id delegate))failureHandler;


/**
 *  WSInviteContact Initialization with shared contacts
 *
 *  @param arrContacts : container of contacts
 *
 *  @return : object
 */
-(id)initWithContacts:(NSMutableArray *)arrContacts;


@end
