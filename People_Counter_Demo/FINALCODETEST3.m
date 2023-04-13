%% People Counter Demo
% Automatically detects and tracks multiple faces in a webcam-acquired
% video stream.
%
% Copyright 2016 The MathWorks, Inc

% Clear everything, create a counter to keep track of the number of
% faces and create a flag to determine whether a special message has been displayed or not. 

clear, clc, close all
count = 0;
imshown = 0;

%% Check the latest value for total number of faces
[initialNum1,latestDate1] = thingSpeakRead(1731876,'ReadKey','8AJGXT8OYKEOV0G2');
[initialNum2,latestDate2] = thingSpeakRead(1731876,'ReadKey','8AJGXT8OYKEOV0G2');




%% Initialize objects for the video device, face detector, and KLT object tracker.
%  Make sure the tracker does not overwrite old entries if there is already
%  data in the channel.

mypi = raspi();
vidObj = cameraboard(mypi,'Resolution','640x480');
%vidObj = webcam();

faceDetector1 = vision.CascadeObjectDetector('MaxSize',[150 150]);%'MaxSize',[150 150]; % Finds faces by default
faceDetector2 = vision.PeopleDetector('WindowStride',[8 8]);%'MaxSize',[150 150]; % Finds faces by default

tracker1 = MultiObjectTrackerKLT;
tracker2 = MultiObjectTrackerKLT;

if ~isempty(initialNum1)
    tracker1.NextId  = initialNum1(1) + 1;
end

if ~isempty(initialNum2)
    tracker2.NextId  = initialNum2(1) + 1;
end


%% Get a frame for frame-size information
frame1 = snapshot(vidObj);
frame1 = fliplr(frame1);
frameSize1 = size(frame1);

frame2 = snapshot(vidObj);
frame2 = fliplr(frame2);
frameSize2 = size(frame2);



%% Create a video player instance
videoPlayer1  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize1(1:2)+30)]);
videoPlayer2  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize2(1:2)+30)]);


%% Create a timer for logging data
%tim = timer;
%tim.ExecutionMode = 'FixedRate';
%tim.Period = 15;
%tim.TimerFcn = @(x,y) logThingSpeakData(tracker1);
%tim.StartDelay = 5;
timePassed = 0;

%% Add a close button to the figure
fig = findall(groot,'Tag','spcui_scope_framework');
fig = fig(1); %In case there are multiple
setappdata(fig,'RequestedClose',false)
fig.CloseRequestFcn = @(~,~) setappdata(fig,'RequestedClose',true);

%% Iterate until we have successfully detected a face
bboxes1 = [];
while isempty(bboxes1)
    framergb1 = snapshot(vidObj);
    frame1 = rgb2gray(framergb1);
    bboxes1 = faceDetector1.step(frame1);
end
tracker1.addDetections(frame1, bboxes1);

bboxes2 = [];
while isempty(bboxes2)
    framergb2 = snapshot(vidObj);
    frame2 = rgb2gray(framergb2);
    bboxes2 = faceDetector2.step(frame2);
end
tracker2.addDetections(frame2, bboxes2);


%% Loop through the main code until the player is closed
frameNumber1 = 0;
frameNumber2 = 0;

totalExit=0;
totalEntry=0;
insideStore=0;

delete(timerfindall);

disp('Close the video player to exit');
%start(tim)
%thingSpeakWrite(1731876,insideStore,'WriteKey','PA8LFRO2UZPHOOTB')

%T= timer('TimerFcn',@(~,~)writeonts,'ExecutionMode','fixedSpacing','TasksToExecute',inf,'Period',15,'StopFcn',@(~,~)disp("timer is stopped"));
%start(T)    

while ~getappdata(fig,'RequestedClose')
    try
        framergb1 = snapshot(vidObj);
        framergb2 = snapshot(vidObj);
    catch
        framergb1 = snapshot(vidObj);
        framergb2 = snapshot(vidObj);
    end
    framergb1 = fliplr(framergb1);
    frame1 = rgb2gray(framergb1);
    
    framergb2 = fliplr(framergb2);
    frame2 = rgb2gray(framergb2);

    timePassed=timePassed+1;
   
    if (timePassed>250)
         thingSpeakWrite(1731876,insideStore,'WriteKey','PA8LFRO2UZPHOOTB')
         timePassed=0;
    end
    %% Partie 1
    if mod(frameNumber1, 10) == 1
        % (Re)detect faces.
        % NOTE: face detection is more expensive than imresize; we can
        % speed up the implementation by reacquiring faces using a
        % downsampled frame:
        % bboxes = faceDetector.step(frame);
        bboxes1 =  faceDetector1.step(frame1);
        if ~isempty(bboxes1)
            tracker1.addDetections(frame1, bboxes1);
        end

        if ~isempty(bboxes1(:,2))
              if (any(bboxes1(:,2)<280)) && (any(bboxes1(:,2)>200))
                  if (insideStore~=0)
                    totalExit=totalExit+1;
                    disp("Exit: "+totalExit);
                    insideStore=totalEntry-totalExit;
                  end  
                  disp("Inside store: "+ insideStore);
              end
        end

    else
        % Track faces
        tracker1.track(frame1);
    end
    
    if ~isempty(tracker1.Bboxes)
        % If the user is the __ user, show a bounding box around their face
        % with a special message and output a picture of the user.

        % If any new person enters the frame, stop showing the special
            % message and display bounding boxes and tracking points on the
            % detected faces.
            if all(mod(tracker1.BoxIds,5) ~= 0)
                imshown = 0;
            end
            %%%%%%%%%%%% disp(tracker.BoxIds)
            displayFrame1 = insertObjectAnnotation(framergb1, 'rectangle',...
                tracker1.Bboxes, tracker1.BoxIds);
            displayFrame1 = insertMarker(displayFrame1, tracker1.Points);
        
            

        videoPlayer1.step(displayFrame1);
        tracker1.BoxIds;
        
    else
        videoPlayer1.step(framergb1);
    end
        %% Partie 2
    if mod(frameNumber2, 10) == 1
        % (Re)detect faces.
        % NOTE: face detection is more expensive than imresize; we can
        % speed up the implementation by reacquiring faces using a
        % downsampled frame:
        % bboxes = faceDetector.step(frame);
        bboxes2 = faceDetector2.step(frame2);
        if ~isempty(bboxes2)
            tracker2.addDetections(frame2, bboxes2);
        end  

        if ~isempty(bboxes2(:,2))
              if (any(bboxes2(:,2)<80)) && (any(bboxes2(:,2)>20))
                  totalEntry=totalEntry+1;
                  disp("Entry: "+totalEntry);
                  insideStore=totalEntry-totalExit;
                  disp("Inside store: "+insideStore);
              end
        end


    else
        % Track faces
        tracker2.track(frame2);
    end
    
    if ~isempty(tracker2.Bboxes)
        % If the user is the __ user, show a bounding box around their face
        % with a special message and output a picture of the user.

            % If any new person enters the frame, stop showing the special
            % message and display bounding boxes and tracking points on the
            % detected faces.
            
            if all(mod(tracker2.BoxIds,5) ~= 0)
                imshown = 0;
            end


            %%%%%%%%%%%% disp(tracker.BoxIds)
            displayFrame2 = insertObjectAnnotation(framergb2, 'rectangle',...
                tracker2.Bboxes, tracker2.BoxIds,'Color','cyan');
            displayFrame2 = insertMarker(displayFrame2, tracker2.Points);
        
       
        videoPlayer2.step(displayFrame2);
        tracker2.BoxIds;


    else
        videoPlayer2.step(framergb2);
    end

%% End code    
    frameNumber1 = frameNumber1 + 1;
    frameNumber2 = frameNumber2 + 1;
   
end

%% Clean up
release(videoPlayer1)
stop(T);
delete(T);
%% 
clear vidObj
clear fig
clear videoPlayer1