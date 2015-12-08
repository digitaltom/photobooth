photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  function ($scope, $http) {

    $scope.alerts = [];

    $scope.takePicture = function () {
      $http.post('/picture_sets.json').success(function (data) {
        $scope.picture_sets.unshift(data);
      }).error(function (data) {
        //alert(data.error);
        $scope.alerts.push({type: 'danger', msg: data.error});
      })
    };

    $scope.update = function () {
      $http.get('/picture_sets/list.json').success(function (data) {
        $scope.picture_sets = data;
      }).error(function (data) {
        //alert(data.error);
        $scope.alerts.push({type: 'error', msg: data.error});
      })
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.update();

  }]);
