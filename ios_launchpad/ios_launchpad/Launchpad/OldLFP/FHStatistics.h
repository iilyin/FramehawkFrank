/**
 * @file
 * FHStatistics.h
 *
 * Copyright 2012 Framehawk, Inc. All rights reserved.
 * Framehawk SDK Version: 3.0.0.11799  Built: Thu Nov  1 08:36:16 PDT 2012
 *
 * Interface for collecting connection statistics.
 *
 * @brief Connection Statistics file.
 */


/**
 * @class FHStatistics
 * Connection Statistics.
 * This class represents an interface for collecting information
 * from the client at runtime.
 * An instance of this class can be associated with a connection instance, and when
 * requested the connection will update the class's records.
 * @brief Connection Statistics class.
 */

/**
 * Interface to the Framehawk connection statistics.
 */
@protocol FHStatistics <NSObject>

/**
 * Total number of frames processed since the connection was started.
 */
@property (readonly) int framesRefreshed;

/**
 * Approximate Frames Per Second (FPS) rate.
 */
@property (readonly) double framesPerSecond;

/**
 * Number of datagrams received since the last frame refresh.
 */
@property (readonly) int datagramsReceivedPeriod;

/**
 * Number of datagrams received since the connection was started.
 */
@property (readonly) int datagramsReceivedTotal;

/**
 * Number of lost datagrams since the connection was started.
 */
@property (readonly) int lostDatagrams;


@end
