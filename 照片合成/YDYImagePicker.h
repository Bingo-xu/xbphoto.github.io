//
//  YDYImagePicker.h
//  YDYiOS
//
//  Created by fuminghui on 16/5/16.
//  Copyright © 2016年 fuminghui. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^didFinishPickingImageHandle)(NSArray<UIImage *> *photos);
typedef void(^cancelPickingImageHandle)(void);

typedef void(^didFinishTakePhotoHandle)(UIImage * photo);
typedef void(^cancelTakePhotoHandle)(void);

@interface YDYImagePicker : UIViewController


/**
 *  图片选择
 *
 *  @param count       照片最大数
 *  @param isTailor    是否需要切图
 *  @param rootVC      VC入口
 *  @param photosBlock 成功回调
 *  @param cancelBlock 取消回调
 */

- (void)pickerImageWithMaxImagesCount:(NSInteger)count isTailor:(BOOL)isTailor rootVC:(UIViewController *)rootVC PhotosBlock:(didFinishPickingImageHandle)photosBlock cancelBlock:(cancelPickingImageHandle)cancelBlock;

/**
 *  拍照功能
 *
 *  @param rootVC      VC入口
 *  @param isTailor    是否需要切图
 *  @param photosBlock 成功回调
 *  @param cancelBlock 取消回调
 */
- (void)takePhotoWithRootVC:(UIViewController *)rootVC isTailor:(BOOL)isTailor PhotosBlock:(didFinishTakePhotoHandle)photosBlock cancelBlock:(cancelTakePhotoHandle)cancelBlock;


@end
