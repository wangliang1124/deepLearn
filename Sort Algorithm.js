// 交换两个元素
function swap(arr, a, b) {
    [arr[a], arr[b]] = [arr[b], arr[a]];
    return void 0;
}

// 冒泡排序
function bubbleSort(arr) {
    const len = arr.length;
    for (let i = 0; i < len; i++) {
        for (let j = 0; j < len - 1 - i; j++) {
            if (arr[j] > arr[j + 1]) {
                swap(arr, j, j + 1);
            }
        }
    }
    return arr;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(bubbleSort(arr)); // [2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 选择排序
function selectionSort(arr) {
    let len = arr.length;
    let minIndex = 0; // 用于保存最小值的索引

    for (let i = 0; i < len - 1; i++) {
        minIndex = i;
        // 遍历后面的元素和当前认为的最小值进行比较
        for (let j = i + 1; j < len; j++) {
            if (arr[minIndex] > arr[j]) {
                // 比认为的最小值小 交换索引
                minIndex = j;
            }
        }
        // 找到最小值和当前值交换
        if (minIndex !== i) {
            swap(arr, minIndex, i);
        }
    }
    return arr;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(selectionSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 插入排序
function insertionSort(arr) {
    let len = arr.length;
    let pIndex, current; // 前一个元素的索引，当前元素的值
    for (let i = 1; i < len; i++) {
        pIndex = i - 1;
        current = arr[i];

        // 依次把当前元素和前面的元素进行比较
        while (pIndex >= 0 && arr[pIndex] > current) {
            // 比当前的元素大，向后移一位
            arr[pIndex + 1] = arr[pIndex];
            pIndex--;
        }
        // 插入当前元素到合适的位置
        arr[pIndex + 1] = current;
    }
    return arr;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(insertionSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 快速排序 -- 这个方法不改变原数组
function quickSort(arr) {
    let len = arr.length;

    if (len < 2) {
        return arr;
    }

    let middleIndex = Math.floor(len / 2); // 中间元素的索引值
    let baseValue = arr.splice(middleIndex, 1); // 基准值

    let left = []; // 保存小于基准值元素
    let right = []; // 保存大于或等于基准值元素

    for (let i = 0; i < arr.length; i++) {
        if (arr[i] < baseValue) {
            left.push(arr[i]);
        } else {
            right.push(arr[i]);
        }
    }
    return quickSort(left).concat(baseValue, quickSort(right));
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(quickSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 希尔排序
function shellSort(arr) {
    let len = arr.length,
        temp,
        gap = 1;

    while (gap < len / 3) {
        gap = gap * 3 + 1;
    }

    for (gap; gap > 0; gap = Math.floor(gap / 3)) {
        for (let i = gap; i < len; i++) {
            temp = arr[i];
            for (var j = i - gap; j >= 0 && arr[j] > temp; j -= gap) {
                arr[j + gap] = arr[j];
            }
            arr[j + gap] = temp;
        }
    }
    return arr;
}
var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(shellSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 归并排序
function mergeSort(arr) {
    let len = arr.length;
    if (len < 2) {
        return arr;
    }
    let middleIndex = Math.floor(len / 2); // 获取中间元素的索引
    let left = arr.slice(0, middleIndex); // 获取左半部分的元素
    let right = arr.slice(middleIndex); // 获取右半部分的元素

    let merges = function(left, right) {
        // 保存结果的数组
        let result = [];

        while (left.length && right.length) {
            if (left[0] < right[0]) {
                result.push(left.shift());
            } else {
                result.push(right.shift());
            }
        }

        // 如果左半边还有元素
        while (left.length) {
            result.push(left.shift());
        }

        // 如果右半边还有元素
        while (right.length) {
            result.push(right.shift());
        }

        return result;
    };

    return merges(mergeSort(left), mergeSort(right));
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(mergeSort(arr));

/** 
    arr 待排序的数组
    index 元素的下标
    len 数组的长度
**/
function heapify(arr, index, len) {
    let left = 2 * index + 1;
    let right = 2 * index + 2;
    let largest = index;

    if (left < len && arr[left] > arr[largest]) {
        largest = left;
    }

    if (right < len && arr[right] > arr[largest]) {
        largest = right;
    }

    if (largest !== index) {
        swap(arr, index, largest);
        heapify(arr, largest, len);
    }
}

// 堆排序
function heapSort(arr) {
    let len = arr.length;
    for (let i = Math.floor(len / 2); i >= 0; i--) {
        heapify(arr, i, len);
    }

    for (let i = len - 1; i >= 1; i--) {
        swap(arr, 0, i);
        heapify(arr, 0, --len);
    }
    return arr;
}

var arr = [91, 60, 96, 13, 35, 65, 46, 65, 10, 30, 20, 31, 77, 81, 22];
console.log(heapSort(arr)); //[10, 13, 20, 22, 30, 31, 35, 46, 60, 65, 65, 77, 81, 91, 96]

// 计数排序
function countingSort(arr) {
    let index = 0;
    let len = arr.length;
    let min = Math.min.apply(null, arr); // 最小值
    let max = Math.max.apply(null, arr); // 最大值
    let result = []; // 结果数组

    // 向新数组中填充0
    for (let i = min; i <= max; i++) {
        result[i] = 0;
    }
    // 把各个数组中对应的元素计数加一
    for (let i = 0; i < len; i++) {
        result[arr[i]]++;
    }
    // 按照计数的元素进行排序
    for (let i = min; i <= max; i++) {
        while (result[i]-- > 0) {
            arr[index++] = i;
        }
    }
    return arr;
}

var arr = [2, 2, 3, 8, 7, 1, 2, 2, 2, 7, 3, 9, 8, 2, 1, 4, 2, 4, 6, 9, 2];
console.log(countingSort(arr)); //[1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 6, 7, 7, 8, 8, 9, 9]

// 桶排序 -- 不改变原数组
function bucketSort(arr, size = 5) {
    let len = arr.length;
    if (len < 2) {
        return arr;
    }

    // 获取最大值和最小值
    const max = Math.max.apply(null, arr);
    const min = Math.min.apply(null, arr);

    // 计算出桶的数量  size是截距
    const bucketCount = Math.floor((max - min) / size) + 1;
    // 根据桶的个数创建指定长度的数组
    const buckets = new Array(bucketCount);
    // 将每个桶塞到大桶里面去
    for (let i = 0; i < bucketCount; i++) {
        buckets[i] = [];
    }
    // 利用映射函数将数据分配到各个桶里面去
    for (let i = 0; i < arr.length; i++) {
        // 逢size进1
        let index = Math.floor((arr[i] - min) / size);
        buckets[index].push(arr[i]);
    }
    //对每个桶中的数据进行排序--借助于快速排序算法
    for (let i = 0; i < buckets.length; i++) {
        buckets[i] = quickSort(buckets[i]);
    }

    // flatten数组--有点不足就是会将原数组中的String改变为Number
    return buckets
        .join(",")
        .split(",")
        .filter(v => v !== "")
        .map(Number);
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(bucketSort(arr, 4)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 基数排序
function radixSort(arr) {
    const SIZE = 10;
    let len = arr.length;
    let buckets = [];
    let max = Math.max.apply(null, arr); // 数组中的最大值
    let maxLength = String(max).length; // 最大数字的长度

    // 进行循环将桶中的数组填充成数组
    for (let i = 0; i < SIZE; i++) {
        buckets[i] = [];
    }

    // 进行循环--对数据进行操作--放桶的行为
    for (let i = 0; i < maxLength; i++) {
        // 第二轮循环是将数据按照个位数进行分类
        for (let j = 0; j < len; j++) {
            let value = String(arr[j]);
            // 判断长度--进行分类
            if (value.length >= i + 1) {
                let num = Number(value[value.length - 1 - i]); // 依次的从右到左获取各个数字
                //放入对应的桶中
                buckets[num].push(arr[j]);
            } else {
                // 长度不满足的时候，就放在第一个桶中
                buckets[0].push(arr[i]);
            }
        }
        // 将原数组清空
        arr.length = 0;

        //这次循环是依次取出上面分类好的数组存放到原数组中
        for (let j = 0; j < SIZE; j++) {
            // 获取各个桶的长度
            let l = buckets[j].length;
            // 循环取出数据
            for (let k = 0; k < l; k++) {
                arr.push(buckets[j][k]);
            }
            // 将对应的桶清空，方便下次存放数据
            buckets[j] = [];
        }
    }
    return arr;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(radixSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

// 二分搜索
function binarySearch(item) {
    this.quickSort();
    var low = 0,
        high = array.length - 1,
        mid,
        element;
    while (low <= high) {
        mid = Math.floor((low + high) / 2);
        element = array[mid];
        if (element < item) {
            low = mid + 1;
        } else if (element > item) {
            high = mid - 1;
        } else {
            return mid;
        }
    }
    return -1;
}

// 硬币找零-动态规划， d1=1，d2=5，d3=10，d4=25。
// 硬币找零-动态规划， d1=1，d2=5，d3=10，d4=25。
function MinCoinChange(coins) {
    let cache = {};
    const makeChange = function(amount) {
        if (amount <= 0) {
            return [];
        }
        if (cache[amount]) {
            return cache[amount];
        }
        let min = [],
            subMin = [],
            subAmount;
        for (let i = 0; i < coins.length; i++) {
            let coin = coins[i];
            subAmount = amount - coin;
            if (subAmount >= 0) {
                subMin = makeChange(subAmount);
            }
            if (subMin.length < min.length - 1 || !min.length) {
                min = [coin].concat(subMin);
                console.log("sub Min " + subMin + " + " + coin + " for " + amount);
            }
        }
        return (cache[amount] = min);
    };
    return makeChange;
}

var makeChange = new MinCoinChange([1, 5, 10, 25]);
console.log(makeChange(39));

var makeChange = new MinCoinChange([1, 5, 10, 25]);
console.log(makeChange(36));

// 硬币找零-贪心算法
function MinCoinChange(coins) {
    const makeChange = function(amount) {
        let change = [],
            count = 0;
        for (let i = coins.length; i >= 0; i--) {
            let coin = coins[i];
            while (count + coin <= amount) {
                change.push(coin);
                count += coin;
            }
        }
        return change;
    };

    return makeChange;
}

var minCoinChange = new MinCoinChange([1, 5, 10, 25]);
console.log(minCoinChange.makeChange(36));
