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

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL
{
  NSParameterAssert(fileURL);

  NSAssert(fileURL.isFileURL, @"fileURL has to be a file URL.");

  // * * *.

  self = [super init];

  if(!self) return nil;

  _fileURL = fileURL;

  if(![self setup]) return nil;

  return self;
}

#pragma mark - Cleanup

- (void) dealloc
{
  [self cancel];
}

#pragma mark - Public Methods

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

- (BOOL) setup
{
  const char* path = _fileURL.fileSystemRepresentation;

  _fileDescriptor = open(path, O_EVTONLY);

  if(_fileDescriptor < 0) return NO;

  // * * *.

  const unsigned long mask = (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE);

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
    dispatch_source_set_registration_handler(_dispatchSource, ^
    {
      // Nope.
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

      [self.delegate dispatchSourceFileWatcher: strongSelfOrNil fileDidChange: [[strongSelfOrNil class] fileChangeTypeWithVnodeFlags: vnodeFlags]];
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
    });
  }}

  // * * *.

  return YES;
}

+ (KSPDispatchSourceFileChangeType) fileChangeTypeWithVnodeFlags: (unsigned long) vnodeFlags
{
  KSPDispatchSourceFileChangeType fileChangeType;

  if(vnodeFlags & DISPATCH_VNODE_DELETE)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeDelete;
  }

  if(vnodeFlags & DISPATCH_VNODE_WRITE)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeWrite;
  }

  if(vnodeFlags & DISPATCH_VNODE_EXTEND)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeExtend;
  }

  if(vnodeFlags & DISPATCH_VNODE_ATTRIB)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeAttribute;
  }

  if(vnodeFlags & DISPATCH_VNODE_LINK)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeLink;
  }

  if(vnodeFlags & DISPATCH_VNODE_RENAME)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeRename;
  }

  if(vnodeFlags & DISPATCH_VNODE_REVOKE)
  {
    fileChangeType |= KSPDispatchSourceFileChangeTypeRevoke;
  }

  return fileChangeType;
}

@end
