//
//  FormControllerCallback.h
//  ShareKit
//
//  Created by Vilém Kurz on 7/10/13.
//
//

#ifndef ShareKit_FormControllerCallback_h
#define ShareKit_FormControllerCallback_h

@class SHKFormController;

typedef void (^FormControllerCallback) (SHKFormController *);

#define CREATE_FORM_CONTROLLER_CALLBACK(body) \
__weak typeof(self) weakSelf = self;\
FormControllerCallback result = body;\
return result;


#endif
