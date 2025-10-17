%****************************
% filename: pofacets.m
% Project: POFACETS
% Description: Declaration of Global Variables
%              Initial values to variables
%              Initialization of Main Screen
% Author:  Filippos % Chatzigeorgiadis
% Date:   March 2004
% Place: NPS
%*********************************

 clear all; clc; close all;

 global facet ntria modelname  	  
 global coord nvert 
 global scale symplanes
 global comments matrl
 global changed
 global coord1 facet1 scale1 symplanes1 comments1 matrl1
 global coord2 facet2 scale2 symplanes2 comments2 matrl2
 global attach
 global materials
 global thetadeg phideg RCSth RCSph dynr

 
 modelname='New';
 attach=0;
 load('materials.mat','materials');
  
 open('mainscreen.fig');