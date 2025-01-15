#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/pixdesc.h>

int main(int argc, const char *argv[]) {
    const char *url = [[[NSBundle mainBundle] pathForResource:@"video" ofType:@"h264"] UTF8String];
    if (argc == 2) {
        url = argv[1];
        return 1;
    }

    AVFormatContext *format;
    int ret = avformat_open_input(&format, url, NULL, NULL);
    if (ret < 0) {
        fprintf(stderr, "ERROR %s\n", av_err2str(ret));
        return 1;
    }

    ret = avformat_find_stream_info(format, NULL);
    if (ret < 0) {
        fprintf(stderr, "ERROR %s\n", av_err2str(ret));
        return 1;
    }

    const AVCodec *c;
    ret = av_find_best_stream(format, AVMEDIA_TYPE_VIDEO, -1, 0, &c, 0);
    if (ret < 0) {
        fprintf(stderr, "ERROR %s\n", av_err2str(ret));
        return 1;
    }

    AVStream *stream = format->streams[ret];
    AVCodecContext *codec  = avcodec_alloc_context3(c);

    ret = avcodec_parameters_to_context(codec, stream->codecpar);
    if (ret < 0) {
        fprintf(stderr, "ERROR %s\n", av_err2str(ret));
        return 1;
    }

    ret = avcodec_open2(codec, c, NULL);
    if (ret < 0) {
        fprintf(stderr, "ERROR %s\n", av_err2str(ret));
        return 1;
    }

    struct SwsContext *sws;

    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    AVFrame *rgb_frame = av_frame_alloc();


    NSApplication *application = [NSApplication sharedApplication];
    NSRect rect = NSMakeRect(300, 200, 1280, 720);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:rect
                                                   styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    CAMetalLayer *metalLayer = [CAMetalLayer layer];
    [window makeKeyAndOrderFront:nil];
    [window.contentView setLayer:metalLayer];
    [window.contentView setWantsLayer:YES];

    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    metalLayer.device = gpu;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.framebufferOnly = YES;
    metalLayer.frame = rect;

    NSString *libraryPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"metallib"];
    id<MTLLibrary> library = [gpu newLibraryWithURL:[NSURL fileURLWithPath:libraryPath] error:nil];
    id<MTLFunction> vertFn = [library newFunctionWithName:@"vert_main"];
    id<MTLFunction> fragFn = [library newFunctionWithName:@"frag_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertFn;
    pipelineDescriptor.fragmentFunction = fragFn;
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;

    id<MTLRenderPipelineState> pipelineState = [gpu newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
    id<MTLCommandQueue> commandQueue = [gpu newCommandQueue];

    BOOL quit = NO;
    while (!quit) {
        NSEvent *event;
        while ((event = [application nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {
            [application sendEvent:event];
            [application updateWindows];
            if ([event type] == NSEventTypeKeyDown) {
                quit = YES;
            }
        }

        ret = av_read_frame(format, pkt);
        if (ret == AVERROR_EOF) break;

        if (pkt->stream_index == stream->index) {
            ret = avcodec_send_packet(codec, pkt);
            if (ret < 0) {
                fprintf(stderr, "ERROR %s\n", av_err2str(ret));
                return 1;
            }

            while (ret >= 0) {
                ret = avcodec_receive_frame(codec, frame);
                if (ret == AVERROR_EOF || ret == AVERROR(EAGAIN)) {
                    break;
                } else if (ret < 0) {
                    fprintf(stderr, "ERROR %s\n", av_err2str(ret));
                    return 1;
                }

                if (!sws) {
                    sws = sws_getContext(frame->width, frame->height, frame->format,
                                         frame->width, frame->height, AV_PIX_FMT_RGBA,
                                         SWS_BILINEAR, NULL, NULL, NULL);
                }

                ret = sws_scale_frame(sws, rgb_frame, frame);
                if (ret < 0) {
                    fprintf(stderr, "ERROR %s\n", av_err2str(ret));
                    return 1;
                }

                MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm 
                                                                                                   width:rgb_frame->width 
                                                                                                  height:rgb_frame->height 
                                                                                               mipmapped:NO];
                id<MTLTexture> texture = [gpu newTextureWithDescriptor:texDesc];
                MTLRegion region = MTLRegionMake2D(0, 0, rgb_frame->width, rgb_frame->height);
                [texture replaceRegion:region mipmapLevel:0 withBytes:rgb_frame->data[0] bytesPerRow:rgb_frame->linesize[0]];

                @autoreleasepool {
                    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
                    if (drawable) {
                        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
                        passDescriptor.colorAttachments[0].texture = drawable.texture;
                        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
                        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
                        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

                        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
                        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
                        [encoder setRenderPipelineState:pipelineState];
                        [encoder setFragmentTexture:texture atIndex:0];
                        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
                        [encoder endEncoding];
                        [commandBuffer presentDrawable:drawable];
                        [commandBuffer commit];
                    }
                }

                av_frame_unref(frame);
            }
        }
        av_packet_unref(pkt);
    }
    return 0;
}
