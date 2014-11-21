//
//  LiveUploadOverwriteOption.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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