#!/usr/bin/env python3
"""
Script for drawing the evolution of a neuron following the Leaky I-F
"""
# Standard libraries
import math
import os
# Third-party libraries
import matplotlib.pyplot as plt
import numpy as np


def format_plotting():
    plt.rcParams['figure.figsize'] = (10, 8)
    plt.rcParams['font.size'] = 22
    #    plt.rcParams['font.family'] = 'Times New Roman'
    plt.rcParams['axes.labelsize'] = plt.rcParams['font.size']
    plt.rcParams['axes.titlesize'] = 1.2 * plt.rcParams['font.size']
    plt.rcParams['legend.fontsize'] = 0.9 * plt.rcParams['font.size']
    plt.rcParams['xtick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['ytick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['savefig.dpi'] = 1000
    plt.rcParams['savefig.format'] = 'eps'
    plt.rcParams['xtick.major.size'] = 3
    plt.rcParams['xtick.minor.size'] = 3
    plt.rcParams['xtick.major.width'] = 1
    plt.rcParams['xtick.minor.width'] = 1
    plt.rcParams['ytick.major.size'] = 3
    plt.rcParams['ytick.minor.size'] = 3
    plt.rcParams['ytick.major.width'] = 1
    plt.rcParams['ytick.minor.width'] = 1
    plt.rcParams['legend.frameon'] = True
    plt.rcParams['legend.loc'] = 'upper right'
    plt.rcParams['axes.linewidth'] = 1
    plt.rcParams['lines.linewidth'] = 1
    plt.rcParams['lines.markersize'] = 3

    plt.gca().spines['right'].set_color('none')
    plt.gca().spines['top'].set_color('none')
    plt.gca().xaxis.set_ticks_position('bottom')
    plt.gca().yaxis.set_ticks_position('left')
    return


def main(u_rest=-70, u_thres=-54, delta_u=15, tau=20):
    """
    Draw the charge-discharge plot of the Leaky I-F model.
    """
    t = (np.arange(0, 100, .1)).astype(np.float)
    synapse_data = np.zeros_like(t)
    synapse_data[100:110] = 1
    synapse_data[300:310] = 1
    # Create the data array. Steady-state at u_rest
    data = (np.ones_like(t) * u_rest).astype(np.float)
    # Synapse at t=10ms
    data[100:] = u_rest + delta_u * np.exp(-(t[100:]-t[100])/tau)
    # Synapse at t=30ms
    delta_u_300 = delta_u+(data[300]-u_rest)
    data[300:] = u_rest + delta_u_300 * np.exp(-(t[300:]-t[300])/tau)
    # Go back to u_rest after spike
    data[301:] = u_rest
    # Plot data
    fig, axes = plt.subplots(2, 1)
    format_plotting()
    axes[0].plot(t, data, drawstyle='steps-pre', zorder=2)
    axes[0].scatter(t[299], -54, marker='x', s=400, c='r', zorder=3)
    axes[0].axhline(y=u_thres, color='k', zorder=2)
    axes[0].grid(zorder=1)
    axes[1].plot(t, synapse_data, color='r', drawstyle='steps-pre')
    axes[1].grid()
    plt.xlabel("Time [ms]")
    axes[0].set_ylabel("Membrane potential (mV)")
    axes[1].set_ylabel("Synapse input")
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/leaky_if.eps'.format(script_path), bbox_inches='tight')
    plt.show()
    return


if __name__ == "__main__":
    main()