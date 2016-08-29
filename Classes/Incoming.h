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

@import UIKit;
@class YapMessage;
#import "AudioMediaItem.h"
#import "PhotoMediaItem.h"
#import "VideoMediaItem.h"
#import <JSQMessagesViewController/JSQMessages.h>

@interface Incoming : NSObject

- (JSQMessage *)create:(YapMessage *)item;

- (void)loadVideoMedia:(YapMessage *)item MediaItem:(VideoMediaItem *)mediaItem;
- (void)loadPhotoMedia:(YapMessage *)item MediaItem:(PhotoMediaItem *)mediaItem;
- (void)loadAudioMedia:(YapMessage *)item MediaItem:(AudioMediaItem *)mediaItem;

@end
