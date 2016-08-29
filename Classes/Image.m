//
// Copyright (c) 2015 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Image.h"

#import "SettingsKeys.h"

NSString* GetImageName() {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddMMyy_HHmmss"];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    stringFromDate = [stringFromDate stringByAppendingString:@"_image.jpg"];
    return [stringFromDate copy];
}

/*
 * Function taked from this website
 * https://www.built.io/blog/2013/03/improving-image-compression-what-weve-learned-from-whatsapp/
 */
UIImage* compressImage(UIImage *image, BOOL isThumb) {
    
    if (!image) {
        return nil;
    }
    
    float actualHeight = image.size.height;
    float actualWidth  = image.size.width;
    float maxHeight = 600.0;
    float maxWidth  = 800.0;
    float imgRatio  = actualWidth/actualHeight;
    float maxRatio  = maxWidth/maxHeight;
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        if(imgRatio < maxRatio){
            // Adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio){
            // Adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else{
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = nil;
    if (isThumb) {
        imageData = UIImageJPEGRepresentation(img, 0.3f);
    } else {
        imageData = UIImageJPEGRepresentation(img, compressionRate());
    }
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
}

CGFloat compressionRate() {
    switch ([SettingsKeys getMessageImageQuality]) {
        case ConversaImageQualityHigh:
            return 0.8f;
        case ConversaImageQualityMedium:
            return 0.5f;
        case ConversaImageQualityLow:
            return 0.2f;
        default:
            break;
    }
    
    return 0.3f;
}