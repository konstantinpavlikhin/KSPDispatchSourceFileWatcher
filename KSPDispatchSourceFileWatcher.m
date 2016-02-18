//
//  KSPDispatchSourceFileWatcher.m
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "KSPDispatchSourceFileWatcher+Private.h"

#import "KSPDispatchSourceFileWatcherDelegate.h"

@implementation KSPDispatchSourceFileWatcher
{
  NSURL* _Nonnull _fileURL;

  int _fileDescriptor;

  dispatch_source_t _dispatchSource;
}

@synthesize fileURL = _fileURL;

#pragma mark - Initialization

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL
{
  return [[self alloc] initWithFileURL: fileURL];
}

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask
{
  return [[self alloc] initWithFileURL: fileURL fileChangeTypeMask: fileChangeTypeMask];
}

- (nullable instancetype) init
{
  NSAssert(NO, @"-init unavailable! Use -%@ instead.", NSStringFromSelector(@selector(initWithFileURL:)));

  return nil;
}

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL
{
  const KSPDispatchSourceFileChangeType allFileChangeTypes = (KSPDispatchSourceFileChangeTypeDelete | KSPDispatchSourceFileChangeTypeWrite | KSPDispatchSourceFileChangeTypeExtend | KSPDispatchSourceFileChangeTypeAttribute | KSPDispatchSourceFileChangeTypeLink | KSPDispatchSourceFileChangeTypeRename | KSPDispatchSourceFileChangeTypeRevoke);

  return [self initWithFileURL: fileURL fileChangeTypeMask: allFileChangeTypes];
}

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask;
{
  NSParameterAssert(fileURL);

  NSAssert(fileURL.isFileURL, @"fileURL has to be a file URL.");

  // * * *.

  self = [super init];

  if(!self) return nil;

  _fileURL = fileURL;

  if(![self setupWithFileChangeTypeMask: fileChangeTypeMask]) return nil;

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

- (BOOL) setupWithFileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask
{
  const char* path = _fileURL.fileSystemRepresentation;

  _fileDescriptor = open(path, O_EVTONLY);

  if(_fileDescriptor < 0) return NO;

  // * * *.

  const unsigned long mask = [[self class] vnodeFlagsWithFileChangeTypeMask: fileChangeTypeMask];

  _dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, _fileDescriptor, mask, dispatch_get_main_queue());

  if(_dispatchSource == NULL)
  {
    close(_fileDescriptor);

    _fileDescriptor = -1;

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

      [strongSelfOrNil.delegate dispatchSourceFileWatcher: strongSelfOrNil fileDidChange: [[strongSelfOrNil class] fileChangeTypeMaskWithVnodeFlags: vnodeFlags]];
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

@end
