#!/usr/bin/env python3
"""
Error estimator top level module
"""
# Standard libraries
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


def main(tau=10):
    """
    Make a plot of the EPSC rule (Hebb's rule)
    """
    t = np.arange(-50, 50, 1)
    # Create the data array. Non linear equation divided in 2 parts,
    # plus the zero.
    data1 = -np.exp(-np.abs(t[:50])/tau)
    data2 = np.exp(-np.abs(t[51:])/tau)
    data = np.hstack((data1, 0, data2))
    # Plot data
    format_plotting()
    plt.plot(t, data)
    plt.grid()
    plt.xlabel("Time difference [ms]")
    plt.ylabel("EPSC amplitude")
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/epsc_plot.eps'.format(script_path), bbox_inches='tight')
    plt.show()


if __name__ == "__main__":
    main()
