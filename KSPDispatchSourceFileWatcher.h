//
//  KSPDispatchSourceFileWatcher.h
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KSPDispatchSourceFileChangeType.h"

// * * *.

extern NSString* _Nonnull const KSPDispatchSourceFileWatcherErrorDomain;

// * * *.

typedef NS_ENUM(NSUInteger, KSPDispatchSourceFileWatcherError)
{
  KSPDispatchSourceFileWatcherErrorUnableToOpenFile = 0,

  KSPDispatchSourceFileWatcherErrorUnableToCreateDispatchSource = 1
};

// * * *.

@protocol KSPDispatchSourceFileWatcherDelegate;

// * * *.

@interface KSPDispatchSourceFileWatcher : NSObject

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL error: (NSError* _Nullable * _Nullable) errorOrNull;

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask error: (NSError* _Nullable * _Nullable) errorOrNull;

- (nullable instancetype) init NS_UNAVAILABLE;

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL error: (NSError* _Nullable * _Nullable) errorOrNull;

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask error: (NSError* _Nullable * _Nullable) errorOrNull NS_DESIGNATED_INITIALIZER;

@property(readonly, strong, nonatomic, nonnull) NSURL* fileURL;

@property(readonly, assign, nonatomic) KSPDispatchSourceFileChangeType fileChangeTypeMask;

@property(readwrite, weak, nonatomic, nullable) id<KSPDispatchSourceFileWatcherDelegate> delegate;

- (void) resume;

- (void) suspend;

- (void) cancel;

@end
