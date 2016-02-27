//
//  KSPDispatchSourceFileWatcher.m
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "KSPDispatchSourceFileWatcher+Private.h"

#import "KSPDispatchSourceFileWatcherDelegate.h"

// * * *.

NSString* const KSPDispatchSourceFileWatcherErrorDomain = @"com.konstantinpavlikhin.KSPDispatchSourceFileWatcher.ErrorDomain";

// * * *.

@implementation KSPDispatchSourceFileWatcher
{
  NSURL* _Nonnull _fileURL;

  int _fileDescriptor;

  dispatch_queue_t _serialQueue;

  dispatch_source_t _dispatchSource;
}

@synthesize fileURL = _fileURL;

#pragma mark - Initialization

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL error: (NSError* _Nullable * _Nullable) errorOrNull
{
  return [[self alloc] initWithFileURL: fileURL error: errorOrNull];
}

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask error: (NSError* _Nullable * _Nullable) errorOrNull
{
  return [[self alloc] initWithFileURL: fileURL fileChangeTypeMask: fileChangeTypeMask error: errorOrNull];
}

- (nullable instancetype) init
{
  NSAssert(NO, @"-init unavailable! Use -%@ instead.", NSStringFromSelector(@selector(initWithFileURL:error:)));

  return nil;
}

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL error: (NSError* _Nullable * _Nullable) errorOrNull
{
  const KSPDispatchSourceFileChangeType allFileChangeTypes = (KSPDispatchSourceFileChangeTypeDelete | KSPDispatchSourceFileChangeTypeWrite | KSPDispatchSourceFileChangeTypeExtend | KSPDispatchSourceFileChangeTypeAttribute | KSPDispatchSourceFileChangeTypeLink | KSPDispatchSourceFileChangeTypeRename | KSPDispatchSourceFileChangeTypeRevoke);

  return [self initWithFileURL: fileURL fileChangeTypeMask: allFileChangeTypes error: errorOrNull];
}

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask error: (NSError* _Nullable * _Nullable) errorOrNull
{
  NSParameterAssert(fileURL);

  NSAssert(fileURL.isFileURL, @"fileURL has to be a file URL.");

  // * * *.

  self = [super init];

  if(!self) return nil;

  _fileURL = fileURL;

  if(![self setupWithFileChangeTypeMask: fileChangeTypeMask error: errorOrNull]) return nil;

  return self;
}

#pragma mark - Cleanup

- (void) dealloc
{
  [self cancel];
}

#pragma mark - Public Methods

- (KSPDispatchSourceFileChangeType) fileChangeTypeMask
{
  const unsigned long vnodeFlags = dispatch_source_get_mask(_dispatchSource);

  return [[self class] fileChangeTypeMaskWithVnodeFlags: vnodeFlags];
}

- (void) resume
{
  if(_dispatchSource)
  {
    dispatch_resume(_dispatchSource);
  }
}

- (void) suspend
{
  if(_dispatchSource)
  {
    dispatch_suspend(_dispatchSource);
  }
}

- (void) cancel
{
  if(_dispatchSource)
  {
    dispatch_source_cancel(_dispatchSource);
  }
}

#pragma mark - Private Methods

- (BOOL) setupWithFileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask error: (NSError* _Nullable * _Nullable) errorOrNull
{
  const char* path = _fileURL.fileSystemRepresentation;

  _fileDescriptor = open(path, O_EVTONLY);

  if(_fileDescriptor < 0)
  {
    if(errorOrNull != NULL)
    {
      *errorOrNull = [[self class] unableToOpenFileErrorWithUnderlyingErrorCode: errno fileURL: _fileURL filePath: path];
    }

    return NO;
  }

  // * * *.

  const unsigned long mask = [[self class] vnodeFlagsWithFileChangeTypeMask: fileChangeTypeMask];

  _serialQueue = dispatch_queue_create("com.konstantinpavlikhin.KSPDispatchSourceFileWatcher.SerialQueue", DISPATCH_QUEUE_SERIAL);

  _dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, _fileDescriptor, mask, _serialQueue);

  if(_dispatchSource == NULL)
  {
    close(_fileDescriptor);

    _fileDescriptor = -1;

    // * * *.

    if(errorOrNull != NULL)
    {
      *errorOrNull = [[self class] unableToCreateDispatchSourceErrorWithFileURL: _fileURL filePath: path];
    }

    // * * *.

    return NO;
  }

  // * * *.

  {{
    __weak typeof(self) const weakSelf = self;

    dispatch_source_set_registration_handler(_dispatchSource, ^
    {
      __strong typeof(self) _Nullable const strongSelfOrNil = weakSelf;

      if(!strongSelfOrNil) return;

      // * * *.

      if([strongSelfOrNil.delegate respondsToSelector: @selector(dispatchSourceFileWatcherDidRegister:)])
      {
        [strongSelfOrNil.delegate dispatchSourceFileWatcherDidRegister: strongSelfOrNil];
      }
    });
  }}

  // * * *.

  {{
    __weak typeof(self) const weakSelf = self;

    dispatch_source_set_event_handler(_dispatchSource, ^
    {
      __strong typeof(self) _Nullable const strongSelfOrNil = weakSelf;

      if(!strongSelfOrNil) return;

      // * * *.

      const unsigned long vnodeFlags = dispatch_source_get_data(_dispatchSource);

      [strongSelfOrNil.delegate dispatchSourceFileWatcher: strongSelfOrNil didObserveChange: [[strongSelfOrNil class] fileChangeTypeMaskWithVnodeFlags: vnodeFlags]];
    });
  }}

  // * * *.

  {{
    __weak typeof(self) const weakSelf = self;

    dispatch_source_set_cancel_handler(_dispatchSource, ^
    {
      __strong typeof(self) _Nullable const strongSelfOrNil = weakSelf;

      if(!strongSelfOrNil) return;

      // * * *.

      if((strongSelfOrNil->_fileDescriptor) >= 0)
      {
        close(strongSelfOrNil->_fileDescriptor);

        strongSelfOrNil->_fileDescriptor = -1;
      }

      // * * *.

      if([strongSelfOrNil.delegate respondsToSelector: @selector(dispatchSourceFileWatcherDidCancel:)])
      {
        [strongSelfOrNil.delegate dispatchSourceFileWatcherDidCancel: strongSelfOrNil];
      }
    });
  }}

  // * * *.

  return YES;
}

#pragma mark - Private Methods | KSPDispatchSourceFileChangeType ⟷ VNode Flags Mapping

+ (unsigned long) vnodeFlagsWithFileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask
{
  unsigned long vnodeFlags = 0;

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeDelete)
  {
    vnodeFlags |= DISPATCH_VNODE_DELETE;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeWrite)
  {
    vnodeFlags |= DISPATCH_VNODE_WRITE;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeExtend)
  {
    vnodeFlags |= DISPATCH_VNODE_EXTEND;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeAttribute)
  {
    vnodeFlags |= DISPATCH_VNODE_ATTRIB;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeLink)
  {
    vnodeFlags |= DISPATCH_VNODE_LINK;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeRename)
  {
    vnodeFlags |= DISPATCH_VNODE_RENAME;
  }

  if(fileChangeTypeMask & KSPDispatchSourceFileChangeTypeRevoke)
  {
    vnodeFlags |= DISPATCH_VNODE_REVOKE;
  }

  return vnodeFlags;
}

+ (KSPDispatchSourceFileChangeType) fileChangeTypeMaskWithVnodeFlags: (unsigned long) vnodeFlags
{
  KSPDispatchSourceFileChangeType fileChangeTypeMask = 0;

  if(vnodeFlags & DISPATCH_VNODE_DELETE)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeDelete;
  }

  if(vnodeFlags & DISPATCH_VNODE_WRITE)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeWrite;
  }

  if(vnodeFlags & DISPATCH_VNODE_EXTEND)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeExtend;
  }

  if(vnodeFlags & DISPATCH_VNODE_ATTRIB)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeAttribute;
  }

  if(vnodeFlags & DISPATCH_VNODE_LINK)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeLink;
  }

  if(vnodeFlags & DISPATCH_VNODE_RENAME)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeRename;
  }

  if(vnodeFlags & DISPATCH_VNODE_REVOKE)
  {
    fileChangeTypeMask |= KSPDispatchSourceFileChangeTypeRevoke;
  }

  return fileChangeTypeMask;
}

#pragma mark - Private Methods | Errors

+ (nonnull NSError*) unableToOpenFileErrorWithUnderlyingErrorCode: (NSInteger) underlyingErrorCode fileURL: (nonnull NSURL*) fileURL filePath: (const char*) path
{
  NSError* const underlyingError  = [NSError errorWithDomain: NSPOSIXErrorDomain code: underlyingErrorCode userInfo: nil];

  // * * *.

  NSMutableDictionary* const userInfo = [NSMutableDictionary dictionary];

  userInfo[NSUnderlyingErrorKey] = underlyingError;

  userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Unable to open a file.", nil);

  userInfo[NSStringEncodingErrorKey] = @(NSUTF8StringEncoding);

  userInfo[NSURLErrorKey] = fileURL;

  userInfo[NSFilePathErrorKey] = [NSString stringWithUTF8String: path];

  // * * *.

  return [NSError errorWithDomain: KSPDispatchSourceFileWatcherErrorDomain code: KSPDispatchSourceFileWatcherErrorUnableToOpenFile userInfo: userInfo];
}

+ (nonnull NSError*) unableToCreateDispatchSourceErrorWithFileURL: (nonnull NSURL*) fileURL filePath: (const char*) path
{
  NSMutableDictionary* const userInfo = [NSMutableDictionary dictionary];

  // * * *.

  userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Unable to create a dispatch source.", nil);

  userInfo[NSStringEncodingErrorKey] = @(NSUTF8StringEncoding);

  userInfo[NSURLErrorKey] = fileURL;

  userInfo[NSFilePathErrorKey] = [NSString stringWithUTF8String: path];

  // * * *.

  return [NSError errorWithDomain: KSPDispatchSourceFileWatcherErrorDomain code: KSPDispatchSourceFileWatcherErrorUnableToCreateDispatchSource userInfo: userInfo];
}

@end
