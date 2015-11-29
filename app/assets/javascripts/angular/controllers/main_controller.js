var photoBoothApp = angular.module('photoBooth', [])

photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  function ($scope, $http) {

    $scope.takePicture = function () {
      $http.post('/picture_sets.json').success(function (data) {
        $scope.picture_sets.unshift(data);
      }).error(function (data) {
        alert(data.error);
      })
    };


    $scope.update = function () {
      $http.get('/picture_sets/list.json').success(function (data) {
        $scope.picture_sets = data;
      }).error(function (data) {
        alert(data.error);
      })
    };

    $scope.update();

  }]);