"""Read OpenModelica .mat result files (format version 1.1)."""
import numpy as np
from scipy.io import loadmat


class Result:
    def __init__(self, path):
        m = loadmat(path, chars_as_strings=False)
        info = m["dataInfo"]
        if info.shape[1] != 4:
            info = info.T
        names = m["name"]
        if names.shape[0] != info.shape[0]:
            names = names.T
        self.names = ["".join(row).rstrip("\x00 ").strip() for row in names.astype(str)]
        self._info = {n: (int(info[i, 0]), int(info[i, 1])) for i, n in enumerate(self.names)}
        d1, d2 = m["data_1"], m["data_2"]
        # store both blocks as (variable, time) arrays; data_1 has two time points
        self._d1 = d1 if d1.shape[1] == 2 else d1.T
        t_len = max(d2.shape) if d2.shape[0] != d2.shape[1] else d2.shape[1]
        self._d2 = d2 if d2.shape[1] == t_len else d2.T
        self.time = self._d2[0]

    def __call__(self, name):
        block, col = self._info[name]
        sign = np.sign(col)
        col = abs(col) - 1
        if block == 2:
            return sign * self._d2[col]
        # parameter or constant: stored in data_1, broadcast to the time grid
        return np.full_like(self.time, sign * self._d1[col][0])

    def at(self, name, t):
        return float(np.interp(t, self.time, self(name)))
