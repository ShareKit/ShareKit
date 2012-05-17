   
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
	&#35;pragma mark - Facebook sharing
	&#8211; (BOOL)handleOpenURL:(NSURL*)url
	{
		NSString* scheme = [url scheme];
    	if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
       		return [SHKFacebook handleOpenURL:url];
    	return YES;
	}

	&#8211; (BOOL)application:(UIApplication *)application 
	            openURL:(NSURL *)url 
	  sourceApplication:(NSString *)sourceApplication 
	         annotation:(id)annotation 
	{
	    return [self handleOpenURL:url];
	}

	&#8211; (BOOL)application:(UIApplication *)application 
	      handleOpenURL:(NSURL *)url 
	{
	    return [self handleOpenURL:url];  
	}
```
Добавляем в plist приложения такую ветку:

![Property List][1]
где 0000 - идентификатор приложения в Facebook(SHKFacebookAppID в SHKConfig.h)


  [1]: https://github.com/miksayer/ShareKit/raw/master/Images/plist.png