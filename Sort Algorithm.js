// 交换两个元素
function swap(arr, a, b) {
    [arr[a], arr[b]] = [arr[b], arr[a]];
    return void 0;
}

/* 
    1、冒泡排序（Bubble Sort）
    冒泡排序是一种简单的排序算法。它重复地走访过要排序的数列，一次比较两个元素，如果它们的顺序错误就把它们交换过来。走访数列的工作是重复地进行直到没有再需要交换，也就是说该数列已经排序完成。这个算法的名字由来是因为越小的元素会经由交换慢慢“浮”到数列的顶端。 

    1.1 算法描述
    比较相邻的元素。如果第一个比第二个大，就交换它们两个；
    对每一对相邻元素作同样的工作，从开始第一对到结尾的最后一对，这样在最后的元素应该会是最大的数；
    针对所有的元素重复以上的步骤，除了最后一个；
    重复步骤1~3，直到排序完成。
*/
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

/* 
    2、选择排序（Selection Sort）
    选择排序(Selection-sort)是一种简单直观的排序算法。它的工作原理：首先在未排序序列中找到最小（大）元素，存放到排序序列的起始位置，然后，再从剩余未排序元素中继续寻找最小（大）元素，然后放到已排序序列的末尾。以此类推，直到所有元素均排序完毕。 

    2.1 算法描述
    n个记录的直接选择排序可经过n-1趟直接选择排序得到有序结果。具体算法描述如下：
    初始状态：无序区为R[1..n]，有序区为空；
    第i趟排序(i=1,2,3…n-1)开始时，当前有序区和无序区分别为R[1..i-1]和R(i..n）。该趟排序从当前无序区中-选出关键字最小的记录 R[k]，将它与无序区的第1个记录R交换，使R[1..i]和R[i+1..n)分别变为记录个数增加1个的新有序区和记录个数减少1个的新无序区；
    n-1趟结束，数组有序化了。
*/
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

/* 
    3、插入排序（Insertion Sort）
    插入排序（Insertion-Sort）的算法描述是一种简单直观的排序算法。它的工作原理是通过构建有序序列，对于未排序数据，在已排序序列中从后向前扫描，找到相应位置并插入。

    3.1 算法描述
    一般来说，插入排序都采用in-place在数组上实现。具体算法描述如下：

    从第一个元素开始，该元素可以认为已经被排序；
    取出下一个元素，在已经排序的元素序列中从后向前扫描；
    如果该元素（已排序）大于新元素，将该元素移到下一位置；
    重复步骤3，直到找到已排序的元素小于或者等于新元素的位置；
    将新元素插入到该位置后；
    重复步骤2~5。
*/
function insertionSort(arr) {
    let len = arr.length;
    let preIndex, currentValue; // 前一个元素的索引，当前元素的值
    for (let i = 1; i < len; i++) {
        preIndex = i - 1;
        currentValue = arr[i];

        // 依次把当前元素和前面的元素进行比较
        while (preIndex >= 0 && arr[preIndex] > currentValue) {
            // 比当前的元素大，向后移一位
            arr[preIndex + 1] = arr[preIndex];
            preIndex--;
        }
        // 插入当前元素到合适的位置
        arr[preIndex + 1] = currentValue;
    }
    return arr;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(insertionSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

/* 
    4、希尔排序（Shell Sort）
    1959年Shell发明，第一个突破O(n2)的排序算法，是简单插入排序的改进版。它与插入排序的不同之处在于，它会优先比较距离较远的元素。希尔排序又叫缩小增量排序。

    4.1 算法描述
    先将整个待排序的记录序列分割成为若干子序列分别进行直接插入排序，具体算法描述：

    选择一个增量序列t1，t2，…，tk，其中ti>tj，tk=1；
    按增量序列个数k，对序列进行k 趟排序；
    每趟排序，根据对应的增量ti，将待排序列分割成若干长度为m 的子序列，分别对各子表进行直接插入排序。仅增量因子为1 时，整个序列作为一个表来处理，表长度即为整个序列的长度。
 */
function shellSort(arr) {
    let len = arr.length;
    let gap = 1;

    // 动态定义间隔序列
    while (gap < len / 5) {
        gap = gap * 5 + 1;
    }

    while (gap > 0) {
        for (let i = gap; i < len; i++) {
            let preIndex = i - gap;
            let currentValue = arr[i];
            while (preIndex >= 0 && arr[preIndex] > currentValue) {
                arr[preIndex + gap] = arr[preIndex];
                preIndex -= gap;
            }
            arr[preIndex + gap] = currentValue;
        }
        gap = Math.floor(gap / 5);
    }
    return arr;
}
var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(shellSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

/* 
    5、归并排序（Merge Sort）
    归并排序是建立在归并操作上的一种有效的排序算法。该算法是采用分治法（Divide and Conquer）的一个非常典型的应用。将已有序的子序列合并，得到完全有序的序列；即先使每个子序列有序，再使子序列段间有序。若将两个有序表合并成一个有序表，称为2-路归并。 

    5.1 算法描述
    把长度为n的输入序列分成两个长度为n/2的子序列；
    对这两个子序列分别采用归并排序；
    将两个排序好的子序列合并成一个最终的排序序列。
*/
function mergeSort(arr) {
    let len = arr.length;
    if (len < 2) {
        return arr;
    }
    let middleIndex = Math.floor(len / 2); // 获取中间元素的索引
    let left = arr.slice(0, middleIndex); // 获取左半部分的元素
    let right = arr.slice(middleIndex); // 获取右半部分的元素

    return merge(mergeSort(left), mergeSort(right));
}

function merge(left, right) {
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
    if (left.length) {
        result = result.concat(left);
    }

    // 如果右半边还有元素
    if (right.length) {
        result = result.concat(right);
    }

    return result;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(mergeSort(arr));

/* 
    6、快速排序（Quick Sort）
    快速排序的基本思想：通过一趟排序将待排记录分隔成独立的两部分，其中一部分记录的关键字均比另一部分的关键字小，则可分别对这两部分记录继续进行排序，以达到整个序列有序。

    6.1 算法描述
    快速排序使用分治法来把一个串（list）分为两个子串（sub-lists）。具体算法描述如下：

    从数列中挑出一个元素，称为 “基准”（pivot）；
    重新排序数列，所有元素比基准值小的摆放在基准前面，所有元素比基准值大的摆在基准的后面（相同的数可以到任一边）。在这个分区退出之后，该基准就处于数列的中间位置。这个称为分区（partition）操作；
    递归地（recursive）把小于基准值元素的子数列和大于基准值元素的子数列排序。
*/
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

function quick(array, left, right) {
    var index;
    if (array.length > 1) {
        index = partition(array, left, right);
    }
    if (left < index - 1) {
        quick(array, left, index - 1);
    }
    if (index < right) {
        quick(array, index, right);
    }
    return array;
}

function partition(array, left, right) {
    let pivot = array[Math.floor((left + right) / 2)];

    while (left <= right) {
        while (array[left] < pivot) {
            left++;
        }
        while (array[right] > pivot) {
            right--;
        }

        if (left <= right) {
            [array[left], array[right]] = [array[right], array[left]];
            left++;
            right--;
        }
    }
    return left;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(quick(arr, 0, arr.length - 1)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]
console.log(quickSort(arr)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

/* 
    7、堆排序（Heap Sort）
    堆排序（Heapsort）是指利用堆这种数据结构所设计的一种排序算法。堆积是一个近似完全二叉树的结构，并同时满足堆积的性质：即子结点的键值或索引总是小于（或者大于）它的父节点。

    7.1 算法描述
    将初始待排序关键字序列(R1,R2….Rn)构建成大顶堆，此堆为初始的无序区；
    将堆顶元素R[1]与最后一个元素R[n]交换，此时得到新的无序区(R1,R2,……Rn-1)和新的有序区(Rn),且满足R[1,2…n-1]<=R[n]；
    由于交换后新的堆顶R[1]可能违反堆的性质，因此需要对当前无序区(R1,R2,……Rn-1)调整为新堆，然后再次将R[1]与无序区最后一个元素交换，得到新的无序区(R1,R2….Rn-2)和新的有序区(Rn-1,Rn)。不断重复此过程直到有序区的元素个数为n-1，则整个排序过程完成。
*/
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

/** 
    arr 待排序的数组
    index 元素的下标
    len 数组的长度
**/
function heapify(arr, index, len) {
    let left = 2 * index + 1;
    let right = 2 * index + 2;
    let maxIndex = index; // 保存最大值的索引

    if (left < len && arr[left] > arr[maxIndex]) {
        maxIndex = left;
    }

    if (right < len && arr[right] > arr[maxIndex]) {
        maxIndex = right;
    }

    if (maxIndex !== index) {
        swap(arr, index, maxIndex);
        heapify(arr, maxIndex, len);
    }
}

var arr = [91, 60, 96, 13, 35, 65, 46, 65, 10, 30, 20, 31, 77, 81, 22];
console.log(heapSort(arr)); //[10, 13, 20, 22, 30, 31, 35, 46, 60, 65, 65, 77, 81, 91, 96]

/* 
    8、计数排序（Counting Sort）
    计数排序不是基于比较的排序算法，其核心在于将输入的数据值转化为键存储在额外开辟的数组空间中。 作为一种线性时间复杂度的排序，计数排序要求输入的数据必须是有确定范围的整数。

    8.1 算法描述
    找出待排序的数组中最大和最小的元素；
    统计数组中每个值为i的元素出现的次数，存入数组C的第i项；
    对所有的计数累加（从C中的第一个元素开始，每一项和前一项相加）；
    反向填充目标数组：将每个元素i放在新数组的第C(i)项，每放一个元素就将C(i)减去1。
*/
function countingSort(arr) {
    let min = Infinity,
        max = -Infinity;
    let counter = [];

    for (let i = 0; i < arr.length; i++) {
        let curr = arr[i];
        if (min > curr) min = curr;
        if (max < curr) max = curr;
        counter[curr] = counter[curr] ? counter[curr] + 1 : 1;
    }

    // 按照计数的元素进行排序
    let index = 0;
    for (let i = min; i <= max; i++) {
        while (counter[i]-- > 0) {
            arr[index++] = i;
        }
    }
    return arr;
}

var arr = [2, 2, 3, 8, 7, 1, 2, 2, 2, 7, 3, 9, 8, 2, 1, 4, 2, 4, 6, 9, 2];
console.log(countingSort(arr)); //[1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 6, 7, 7, 8, 8, 9, 9]

/* 
    9、桶排序（Bucket Sort）
    桶排序是计数排序的升级版。它利用了函数的映射关系，高效与否的关键就在于这个映射函数的确定。桶排序 (Bucket sort)的工作的原理：假设输入数据服从均匀分布，将数据分到有限数量的桶里，每个桶再分别排序（有可能再使用别的排序算法或是以递归方式继续使用桶排序进行排）。

    9.1 算法描述
    设置一个定量的数组当作空桶；
    遍历输入数据，并且把数据一个一个放到对应的桶里去；
    对每个不是空的桶进行排序；
    从不是空的桶里把排好序的数据拼接起来。 
*/
function bucketSort(arr, size = 5) {
    let len = arr.length;
    if (len < 2) {
        return arr;
    }

    const buckets = [];
    const min = Math.min.apply(null, arr);

    // 利用映射函数将数据分配到各个桶里面去
    for (let i = 0; i < len; i++) {
        let index = Math.floor((arr[i] - min) / size);
        if (buckets[index]) {
            // 插入排序
            let bucket = buckets[index];
            let j = bucket.length - 1;
            while (j >= 0 && bucket[j] > arr[i]) {
                bucket[j + 1] = bucket[j];
                j--;
            }
            bucket[j + 1] = arr[i];
        } else {
            buckets[index] = [arr[i]];
        }
    }

    let result = [];
    while (buckets.length) {
        let bucket = buckets.shift();
        if (bucket) {
            result = result.concat(bucket);
        }
    }
    return result;
}

var arr = [3, 44, 38, 5, 47, 15, 36, 26, 27, 2, 46, 4, 19, 50, 48];
console.log(bucketSort(arr, 4)); //[2, 3, 4, 5, 15, 19, 26, 27, 36, 38, 44, 46, 47, 48, 50]

/* 
    10、基数排序（Radix Sort）
    基数排序是按照低位先排序，然后收集；再按照高位排序，然后再收集；依次类推，直到最高位。有时候有些属性是有优先级顺序的，先按低优先级排序，再按高优先级排序。最后的次序就是高优先级高的在前，高优先级相同的低优先级高的在前。

    10.1 算法描述
    取得数组中的最大数，并取得位数；
    arr为原始数组，从最低位开始取每个位组成radix数组；
    对radix进行计数排序（利用计数排序适用于小范围数的特点）；
*/
function radixSort(arr) {
    let mod = 10;
    let dev = 1;
    let maxDigit = String(Math.max.apply(null, arr)).length; // 最大数字的长度
    let counter = [];

    for (let i = 0; i < maxDigit; i++, dev *= 10, mod *= 10) {
        for (let j = 0; j < arr.length; j++) {
            let bucket = Math.floor((arr[j] % mod) / dev);
            if (counter[bucket] == null) {
                counter[bucket] = [];
            }
            counter[bucket].push(arr[j]);
        }

        let pos = 0;
        for (let j = 0; j < counter.length; j++) {
            if (counter[j]) {
                let value = counter[j].shift();
                while (value) {
                    arr[pos++] = value;
                    value = counter[j].shift();
                }
            }
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
