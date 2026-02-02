# Code for Dorsal prefrontal cortex drives perseverative behavior in mice, Lebedeva et al.

In order to run the code, please download the data from here:     

This folder contains data in three folders: figure1 (behaviour only), figure 245 (behavioural and ephys data), figure 67 (optogenetics data).    

Within each of the three folders, you will find a folder for each mouse and within that you will find a folder for each date.    

Inside, there are some (depending on the experiment) of the following files:    

Trials.choices.npy (-1 for left, 1 for right wheel turn)   

Trials.correctAnswers.npy (-1 for left, 1 for right wheel turn)  

Trials.feedback.npy  (0 for white noise, 1 for liquid reward)  

Trials.goCueTimes.npy (in seconds)   

Trials.movementTimes.npy (in seconds)   

Trials.feedbackTimes.npy (in seconds)   

Trials.laserAtGoCue.npy (0 if no laser at go cue, 1 if laser ON)  

Trials.laserAtFeedback.npy (0 if no laser at feedback time, 1 if laser ON)  

spikes.times.npy (in samples; sampling frequency 30 kHz)  

spikes.clusters.npy (cluster ID for every spike; only non-noise clusters)  

Clusters.brainLocation_ccf_2017.txt (name of brain region for every cluster; ordered by cluster index, not cluster ID)  


To run the code, save the data folders onto your computer and change the loadPath... files to point to their location.  

