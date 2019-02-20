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
    t = np.arange(0, 100, 1)
    # Create the data arrays. 2 inputs and 1 output
    input1_data = np.zeros(100)
    input2_data = np.zeros(100)
    output_data = np.zeros(100)
    for i in range(1, 100):
        if not i % 20:
            input1_data[i] = 1
        if not i % 30:
            input2_data[i] = 1
    output_data =  input1_data * input2_data
    # Plot data
    fig, axes = plt.subplots(3, 1)
    format_plotting()
    axes[0].plot(t, input1_data,  drawstyle='steps-pre')
    axes[0].grid()
    axes[0].set_ylabel("Input 1")
    axes[1].plot(t, input2_data,  drawstyle='steps-pre')
    axes[1].grid()
    axes[1].set_ylabel("Input 2")
    axes[2].plot(t, output_data,  drawstyle='steps-pre', color="red")
    axes[2].grid()
    axes[2].set_xlabel("Time [ms]")
    axes[2].set_ylabel("Output")
    fig.tight_layout()
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/coinc_detector_plot.eps'.format(script_path),
                bbox_inches='tight')
    plt.show()


if __name__ == "__main__":
    main()
