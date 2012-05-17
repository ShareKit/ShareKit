ShareKit 2.0 Быстрый Старт
==========================


Скачиваем последнюю версию с GitHub:

	git clone git@github.com:miksayer/ShareKit.git --recursive

Если у вас не установлен git [скачайте его](http://code.google.com/p/git-osx-installer/).

Теперь делаем так:
	
1. Cоздаем новый проект в XCode 4. 
2. Копируем в новый проект папку ShareKit и Submodules из репозитория. 
3. Ключи для социальный сетей и различную информацию(название приложения, его сайт) необходимо прописать в SHKConfig.h. 
4. Если необходимо использовать Facebook, добавляем в App Delegate приложения следующий код:
```objective-c
#pragma mark - Facebook sharing
- (BOOL)handleOpenURL:(NSURL*)url
{
	NSString* scheme = [url scheme];
    if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
        return [SHKFacebook handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
    return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application 
      handleOpenURL:(NSURL *)url 
{
    return [self handleOpenURL:url];  
}
```

Добавляем в plist приложения такую ветку:

![Property List](/Images/plist.png)

где 0000 - идентификатор приложения в Facebook(SHKFacebookAppID в SHKConfig.h)