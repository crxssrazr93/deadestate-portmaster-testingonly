// Port: GMLive is a live-coding tool left on in the shipped build. It indexes every asset at
// start and polls http://localhost:5100 every second. live_call() returns early while
// live_request_guid is undefined, so setting that and removing the object turns it off.
global.live_request_guid = undefined;
global.live_name = undefined;
global.live_result = undefined;
instance_destroy();
