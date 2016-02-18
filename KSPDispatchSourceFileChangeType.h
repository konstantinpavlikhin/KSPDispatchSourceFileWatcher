//
//  KSPDispatchSourceFileChangeType.h
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#ifndef KSPDispatchSourceFileChangeType_h
#define KSPDispatchSourceFileChangeType_h

typedef NS_OPTIONS(NSUInteger, KSPDispatchSourceFileChangeType)
{
  // The filesystem object was deleted from the namespace.
  KSPDispatchSourceFileChangeTypeDelete = 1 << 0,

  // The filesystem object data changed.
  KSPDispatchSourceFileChangeTypeWrite = 1 << 1,

  // The filesystem object changed in size.
  KSPDispatchSourceFileChangeTypeExtend = 1 << 2,

  // The filesystem object metadata changed.
  KSPDispatchSourceFileChangeTypeAttribute = 1 << 3,

  // The filesystem object link count changed.
  KSPDispatchSourceFileChangeTypeLink = 1 << 4,

  // The filesystem object was renamed in the namespace.
  KSPDispatchSourceFileChangeTypeRename = 1 << 5,

  // The filesystem object was revoked.
  KSPDispatchSourceFileChangeTypeRevoke = 1 << 6
};

#endif
