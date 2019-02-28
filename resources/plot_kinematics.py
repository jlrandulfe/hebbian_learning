#!/usr/bin/env python3
"""
Error estimator top level module
"""
# Standard libraries
import os
# Third-party libraries
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal


def format_plotting():
    plt.rcParams['figure.figsize'] = (10, 8)
    plt.rcParams['font.size'] = 22
    #    plt.rcParams['font.family'] = 'Times New Roman'
    plt.rcParams['axes.labelsize'] = plt.rcParams['font.size']
    plt.rcParams['axes.titlesize'] = 1.2 * plt.rcParams['font.size']
    plt.rcParams['legend.fontsize'] = 0.7 * plt.rcParams['font.size']
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
    plt.rcParams['legend.loc'] = 'upper center'
    plt.rcParams['axes.linewidth'] = 1
    plt.rcParams['lines.linewidth'] = 1
    plt.rcParams['lines.markersize'] = 3

    plt.gca().spines['right'].set_color('none')
    plt.gca().spines['top'].set_color('none')
    return


def main(tau=10):
    """
    Plot the velocities and accelerations of an agent from a csv file.
    """
    # Import and scale data
    data = np.genfromtxt("kinematics.csv", delimiter=",", skip_header=1)
    data /= 100000
    kernel = np.ones(80)
    filtered_acc_x = signal.convolve(data[:,2], kernel, "same") / kernel.size
    filtered_acc_y = signal.convolve(data[:,3], kernel, "same") / kernel.size

    # Set plots layout
    format_plotting()
    fig, axes = plt.subplots(2, 1)
    axes_0_aux = axes[0].twinx()
    axes_1_aux = axes[1].twinx()
    # Write data to plots
    axes[0].plot(data[:,0], color="r", label="Velocity")
    axes[0].axhline(y=0, color='k')
    axes_0_aux.plot(data[:,2], label="Acceleration")
    # axes_0_aux.plot(filtered_acc_x, color="g", label="Filtered acc.")

    axes[1].axhline(y=0, color='k')
    axes_1_aux.plot(data[:,3], label="Acceleration")
    axes[1].plot(data[:,1], color="r", label="Velocity")
    # axes_1_aux.plot(filtered_acc_y, color="g", label="Filtered acc.")
    h1, l1 = axes[1].get_legend_handles_labels()
    h2, l2 = axes_1_aux.get_legend_handles_labels()
    # Format plots
    axes[0].grid()
    axes[0].set_ylabel(r"$V_x [\mu m/s]$")
    axes_0_aux.set_ylabel(r"$A_x [\mu m/s^2]$")
    axes[1].grid()
    axes[1].set_ylabel(r"$V_y [\mu m/s]$")
    axes_1_aux.set_ylabel(r"$A_y [\mu m/s^2]$")
    axes[1].set_xlabel("Iteration")
    axes[0].set_ylim(-0.5, 1.5)
    axes[1].set_ylim(-0.5, 1.5)
    axes_0_aux.set_ylim(-0.01, 0.03)
    axes_1_aux.set_ylim(-0.01, 0.03)
    # Shring lower axis and place legend there
    # box = axes[0].get_position()
    # axes[0].set_position([box.x0, box.y0 + box.height * 0.1,
    #              box.width, box.height * 0.9])
    axes[0].legend(h1+h2, l1+l2, bbox_to_anchor=(0.5, 1.2), ncol=3)

    fig.tight_layout()
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/kinematics.eps'.format(script_path),
                bbox_inches='tight')
    plt.show()


if __name__ == "__main__":
    main()
