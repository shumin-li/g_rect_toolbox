%% test create avi (movie)


figure(6)
set(gcf,'color','w','position',[100 100 600 600])
for ii = 1:10
    clf

    plot(1:5, (2:6)*ii,'-ok');
    ylim([0, 60]);

    FF(ii) = getframe(gcf);

end

% create the video writer 
  writerObj = VideoWriter('myVideo.avi');
  writerObj.FrameRate = 0.5; % set the seconds per image
  open(writerObj);
for ii=1:length(FF)
    % convert the image to a frame
    frame = FF(ii) ;    
    writeVideo(writerObj, frame);
end
close(writerObj);
