//
//  LiveUploadOverwriteOption.h
//  Live SDK for iOS
//
//  Created by Lin Wang on 6/26/12.
//  Copyright (c) 2012 Microsoft. All rights reserved.
//

// An enum type representing the overwrite options for upload methods.
typedef enum 
{
    // Overwrite the existing file.
    LiveUploadOverwrite = 0,
    
    // Do not overwrite the existing file.
    LiveUploadDoNotOverwrite = 1,
    
    // Give the uploaded file a new name.
    LiveUploadRename = 2,
    
} LiveUploadOverwriteOption;