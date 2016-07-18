//
//  YDYImagePicker.m
//  YDYiOS
//
//  Created by fuminghui on 16/5/16.
//  Copyright © 2016年 fuminghui. All rights reserved.
//

#import "YDYImagePicker.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "TZImagePickerController.h"
#import "TZImageManager.h"
#import "YDYCameraUtility.h"
#import "VPImageCropperViewController.h"

@interface YDYImagePicker ()<TZImagePickerControllerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,VPImageCropperDelegate>

@property (nonatomic, copy  ) didFinishPickingImageHandle pickingImageHandle;
@property (nonatomic, copy  ) cancelPickingImageHandle    cancelImageHandle;

@property (nonatomic, copy  ) didFinishTakePhotoHandle    takePhotoHandle;
@property (nonatomic, copy  ) cancelTakePhotoHandle       cancelPhotoHandle;

@property (nonatomic, assign) BOOL                        isTailor;

@property (nonatomic, strong) UIViewController            * rootVC;

@end

@implementation YDYImagePicker {
    NSMutableArray *_selectedPhotos;
    NSMutableArray *_selectedAssets;
}


- (void)pickerImageWithMaxImagesCount:(NSInteger)count isTailor:(BOOL)isTailor rootVC:(UIViewController *)rootVC PhotosBlock:(didFinishPickingImageHandle)photosBlock cancelBlock:(cancelPickingImageHandle)cancelBlock {
    
    self.pickingImageHandle = photosBlock;
    self.cancelImageHandle = cancelBlock;
    self.rootVC = rootVC;
    self.isTailor = isTailor;
    [self configImagePickerViewWithMaxImagesCount:count];
}

- (void)takePhotoWithRootVC:(UIViewController *)rootVC isTailor:(BOOL)isTailor  PhotosBlock:(didFinishTakePhotoHandle)photosBlock cancelBlock:(cancelTakePhotoHandle)cancelBlock {
    self.takePhotoHandle = photosBlock;
    self.cancelPhotoHandle = cancelBlock;
    self.rootVC = rootVC;
    self.isTailor = isTailor;
    [self configTakePhotoView];
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    [self commonInit];
    return self;
}

- (void)commonInit {
    _selectedPhotos = [NSMutableArray array];
    _selectedAssets = [NSMutableArray array];
}

- (void)configImagePickerViewWithMaxImagesCount:(NSInteger)count {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:count delegate:self];
    imagePickerVc.isSelectOriginalPhoto = NO;
    imagePickerVc.selectedAssets = _selectedAssets; // optional, 可选的
    
    // Set allow picking video & photo & originalPhoto or not
//     设置是否可以选择视频/图片/原图
     imagePickerVc.allowPickingVideo = NO;
    // imagePickerVc.allowPickingImage = NO;
//     imagePickerVc.allowPickingOriginalPhoto = NO;
    
    [self.rootVC presentViewController:imagePickerVc animated:YES completion:nil];
}


- (void)configTakePhotoView {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"视频问诊需要访问您的相机。\n请在设置-隐私-相机-友德医，启用相机" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    if ([YDYCameraUtility isCameraAvailable] && [YDYCameraUtility doesCameraSupportTakingPhotos]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.delegate = self;
        [self.rootVC presentViewController:controller
                                      animated:YES
                                    completion:^(void){
                                        NSLog(@"Picker View Controller is presented");
                                    }];

    }
}




#pragma mark TZImagePickerControllerDelegate

/// User click cancel button
/// 用户点击了取消
- (void)TZImagePickerControllerDidCancel:(TZImagePickerController *)picker {
    // NSLog(@"cancel");
    if (self.cancelImageHandle) {
        self.cancelImageHandle();
    }
}

/// User finish picking photo，if assets are not empty, user picking original photo.
/// 用户选择好了图片，如果assets非空，则用户选择了原图。
- (void)TZImagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    [picker dismissViewControllerAnimated:YES completion:^{
        _selectedPhotos = [NSMutableArray arrayWithArray:photos];
        _selectedAssets = [NSMutableArray arrayWithArray:assets];
        if (self.isTailor&&photos.count == 1) {
           UIImage *  portraitImg = [YDYCameraUtility imageByScalingToMaxSize:photos[0]];
            VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width) limitScaleRatio:3.0];
            imgCropperVC.delegate = self;
            [self.rootVC presentViewController:imgCropperVC animated:YES completion:nil];
            
        }
        if (!self.isTailor){
            if (_selectedPhotos.count > 0 && self.pickingImageHandle) {
                self.pickingImageHandle(_selectedPhotos);
            }
        }
    
    }];
}

/// User finish picking video,
/// 用户选择好了视频
- (void)TZImagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[coverImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
//    _layout.itemCount = _selectedPhotos.count;
    // open this code to send video / 打开这段代码发送视频
    // [[TZImageManager manager] getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
    // NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
    // Export completed, send video here, send by outputPath or NSData
    // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
    
//    // }];
//    [_collectionView reloadData];
//    _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma makr - UIImagePickerControllerDelegate



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        portraitImg = [YDYCameraUtility imageByScalingToMaxSize:portraitImg];
        if (self.isTailor) {
            VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width) limitScaleRatio:3.0];
            imgCropperVC.delegate = self;
            [self.rootVC presentViewController:imgCropperVC animated:YES completion:nil];
        }else {
            if (self.takePhotoHandle) {
                self.takePhotoHandle(portraitImg);
            }
        }

    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.cancelPhotoHandle) {
        self.cancelPhotoHandle();
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark VPImageCropperDelegate

- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    if (self.takePhotoHandle) {
        self.takePhotoHandle(editedImage);
    }
    if (self.pickingImageHandle) {
        [_selectedPhotos removeAllObjects];
        [_selectedPhotos addObject:editedImage];
        self.pickingImageHandle(_selectedPhotos);
    }
    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController {
    
    if (self.cancelPhotoHandle) {
        self.cancelPhotoHandle();
    }
    if (self.cancelImageHandle) {
        self.cancelImageHandle();
    }
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end
